# frozen_string_literal: true

RSpec.describe Taocp::Mix::Instruction do
  describe "initialization" do
    it "creates an instruction with default values" do
      inst = described_class.new
      expect(inst.address).to eq(0)
      expect(inst.index).to eq(0)
      expect(inst.field).to eq(0)
      expect(inst.opcode).to eq(0)
      expect(inst.sign).to eq(1)
    end

    it "creates an instruction with specified values" do
      inst = described_class.new(address: 100, index: 1, field: 5, opcode: 8, sign: -1)
      expect(inst.address).to eq(100)
      expect(inst.index).to eq(1)
      expect(inst.field).to eq(5)
      expect(inst.opcode).to eq(8)
      expect(inst.sign).to eq(-1)
    end
  end

  describe "#to_word" do
    it "encodes a simple instruction" do
      inst = described_class.new(address: 100, index: 1, field: 5, opcode: 8, sign: 1)
      word = inst.to_word

      # 100 = 1*64 + 36
      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([1, 36, 1, 5, 8])
    end

    it "encodes an instruction with zero address" do
      inst = described_class.new(address: 0, index: 0, field: 0, opcode: described_class::NOP, sign: 1)
      word = inst.to_word

      expect(word.bytes).to eq([0, 0, 0, 0, 0])
    end

    it "encodes an instruction with maximum address" do
      # Max address is 4095 = 63*64 + 63
      inst = described_class.new(address: 4095, index: 6, field: 5, opcode: 8, sign: -1)
      word = inst.to_word

      expect(word.sign).to eq(-1)
      expect(word.bytes).to eq([63, 63, 6, 5, 8])
    end

    it "encodes LDA instruction" do
      # LDA 2000
      inst = described_class.new(address: 2000, index: 0, field: 5, opcode: described_class::LDA)
      word = inst.to_word

      # 2000 = 31*64 + 16
      expect(word.bytes[0]).to eq(31)
      expect(word.bytes[1]).to eq(16)
      expect(word.bytes[4]).to eq(8)  # LDA opcode
    end
  end

  describe ".from_word" do
    it "decodes a simple instruction" do
      # 100 = 1*64 + 36
      word = Taocp::Mix::Word.new(sign: 1, bytes: [1, 36, 1, 5, 8])
      inst = described_class.from_word(word)

      expect(inst.address).to eq(100)
      expect(inst.index).to eq(1)
      expect(inst.field).to eq(5)
      expect(inst.opcode).to eq(8)
      expect(inst.sign).to eq(1)
    end

    it "decodes NOP instruction" do
      word = Taocp::Mix::Word.new(sign: 1, bytes: [0, 0, 0, 0, 0])
      inst = described_class.from_word(word)

      expect(inst.address).to eq(0)
      expect(inst.opcode).to eq(0)
    end

    it "decodes instruction with negative sign" do
      word = Taocp::Mix::Word.new(sign: -1, bytes: [0, 50, 2, 13, 8])
      inst = described_class.from_word(word)

      expect(inst.address).to eq(50)
      expect(inst.sign).to eq(-1)
    end
  end

  describe "round-trip encoding" do
    it "round-trips simple instructions" do
      [
        { address: 0, index: 0, field: 0, opcode: 0, sign: 1 },
        { address: 100, index: 1, field: 5, opcode: 8, sign: 1 },
        { address: 2000, index: 3, field: 13, opcode: 24, sign: -1 },
        { address: 4095, index: 6, field: 63, opcode: 63, sign: 1 },
      ].each do |params|
        original = described_class.new(**params)
        word = original.to_word
        decoded = described_class.from_word(word)

        expect(decoded.address).to eq(original.address)
        expect(decoded.index).to eq(original.index)
        expect(decoded.field).to eq(original.field)
        expect(decoded.opcode).to eq(original.opcode)
        expect(decoded.sign).to eq(original.sign)
      end
    end
  end

  describe "#effective_address" do
    let(:registers) { Taocp::Mix::Registers.new }

    it "returns address when index is 0" do
      inst = described_class.new(address: 100, index: 0)
      expect(inst.effective_address(registers)).to eq(100)
    end

    it "adds index register value when index > 0" do
      registers.set_index_i(1, 50)
      inst = described_class.new(address: 100, index: 1, sign: 1)
      expect(inst.effective_address(registers)).to eq(150)
    end

    it "handles negative address sign" do
      registers.set_index_i(2, 30)
      inst = described_class.new(address: 100, index: 2, sign: -1)
      # -100 + 30 = -70, but address is abs = 70
      expect(inst.effective_address(registers)).to eq(70)
    end

    it "handles zero index register" do
      registers.set_index_i(3, 0)
      inst = described_class.new(address: 200, index: 3)
      expect(inst.effective_address(registers)).to eq(200)
    end

    it "uses different index registers" do
      (1..6).each do |i|
        registers.set_index_i(i, i * 10)
        inst = described_class.new(address: 100, index: i)
        expect(inst.effective_address(registers)).to eq(100 + i * 10)
      end
    end
  end

  describe "opcode constants" do
    it "defines load opcodes" do
      expect(described_class::LDA).to eq(8)
      expect(described_class::LDX).to eq(15)
      expect(described_class::LD1).to eq(9)
    end

    it "defines store opcodes" do
      expect(described_class::STA).to eq(24)
      expect(described_class::STX).to eq(31)
      expect(described_class::STZ).to eq(33)
    end

    it "defines arithmetic opcodes" do
      expect(described_class::ADD).to eq(1)
      expect(described_class::SUB).to eq(2)
      expect(described_class::MUL).to eq(3)
      expect(described_class::DIV).to eq(4)
    end

    it "defines comparison opcodes" do
      expect(described_class::CMPA).to eq(56)
      expect(described_class::CMPX).to eq(63)
    end

    it "defines special opcodes" do
      expect(described_class::NOP).to eq(0)
      expect(described_class::HLT).to eq(5)
    end
  end

  describe "#to_s" do
    it "formats instruction as string" do
      inst = described_class.new(address: 100, index: 1, field: 5, opcode: 8)
      expect(inst.to_s).to eq("+0100 1 5 8")
    end

    it "formats negative instruction" do
      inst = described_class.new(address: 50, index: 2, field: 13, opcode: 24, sign: -1)
      expect(inst.to_s).to eq("-0050 2 13 24")
    end
  end
end
