# frozen_string_literal: true

RSpec.describe "MIX Instruction Execution" do
  let(:machine) { Quackers::Mix::Machine.new }
  let(:inst_class) { Quackers::Mix::Instruction }
  let(:word_class) { Quackers::Mix::Word }

  describe "Load instructions" do
    describe "LDA" do
      it "loads a word from memory into register A" do
        # Store a value in memory
        machine.memory[100] = word_class.from_i(12345)

        # Create LDA instruction: LDA 100
        inst = inst_class.new(address: 100, field: 5, opcode: inst_class::LDA)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.to_i).to eq(12345)
      end

      it "loads with field specification" do
        # Store word with distinct bytes
        machine.memory[100] = word_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

        # LDA 100(1:5) - load bytes only, not sign
        inst = inst_class.new(address: 100, field: word_class.encode_field_spec(1, 5), opcode: inst_class::LDA)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.sign).to eq(1)  # Positive when not loading sign
        expect(machine.registers.a.bytes).to eq([10, 20, 30, 40, 50])
      end
    end

    describe "LDX" do
      it "loads a word into register X" do
        machine.memory[200] = word_class.from_i(999)

        inst = inst_class.new(address: 200, field: 5, opcode: inst_class::LDX)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.x.to_i).to eq(999)
      end
    end

    describe "LD1-LD6" do
      it "loads into index registers" do
        machine.memory[50] = word_class.from_i(42)

        # LD1 50
        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::LD1)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.get_index_i(1)).to eq(42)
      end
    end
  end

  describe "Store instructions" do
    describe "STA" do
      it "stores register A to memory" do
        machine.registers.a = word_class.from_i(777)

        # STA 100
        inst = inst_class.new(address: 100, field: 5, opcode: inst_class::STA)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.memory[100].to_i).to eq(777)
      end

      it "stores with field specification" do
        machine.registers.a = word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
        machine.memory[100] = word_class.new(sign: 1, bytes: [10, 20, 30, 40, 50])

        # STA 100(3:5) - store bytes 3-5 only
        inst = inst_class.new(address: 100, field: word_class.encode_field_spec(3, 5), opcode: inst_class::STA)
        machine.memory[0] = inst.to_word

        machine.step

        # Memory should have original bytes 1-2, then bytes 3-5 from A
        expect(machine.memory[100].sign).to eq(1)  # Sign unchanged
        expect(machine.memory[100].bytes).to eq([10, 20, 3, 4, 5])
      end
    end

    describe "STX" do
      it "stores register X to memory" do
        machine.registers.x = word_class.from_i(888)

        inst = inst_class.new(address: 200, field: 5, opcode: inst_class::STX)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.memory[200].to_i).to eq(888)
      end
    end

    describe "STZ" do
      it "stores zero to memory" do
        machine.memory[150] = word_class.from_i(999)

        # STZ 150
        inst = inst_class.new(address: 150, field: 5, opcode: inst_class::STZ)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.memory[150].to_i).to eq(0)
      end
    end

    describe "STJ" do
      it "stores J register to memory" do
        machine.registers.j = 123

        inst = inst_class.new(address: 300, field: 5, opcode: inst_class::STJ)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.memory[300].to_i).to eq(123)
      end
    end
  end

  describe "Arithmetic instructions" do
    describe "ADD" do
      it "adds memory value to register A" do
        machine.registers.a = word_class.from_i(100)
        machine.memory[50] = word_class.from_i(200)

        # ADD 50
        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::ADD)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.to_i).to eq(300)
      end

      it "handles negative numbers" do
        machine.registers.a = word_class.from_i(100)
        machine.memory[50] = word_class.from_i(-50)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::ADD)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.to_i).to eq(50)
      end

      it "sets overflow flag on overflow" do
        machine.registers.a = word_class.from_i(word_class::MAX_VALUE)
        machine.memory[50] = word_class.from_i(1)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::ADD)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.overflow).to eq(true)
      end
    end

    describe "SUB" do
      it "subtracts memory value from register A" do
        machine.registers.a = word_class.from_i(300)
        machine.memory[50] = word_class.from_i(100)

        # SUB 50
        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::SUB)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.to_i).to eq(200)
      end

      it "produces negative results" do
        machine.registers.a = word_class.from_i(100)
        machine.memory[50] = word_class.from_i(200)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::SUB)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.to_i).to eq(-100)
      end
    end

    describe "MUL" do
      it "multiplies register A by memory value" do
        machine.registers.a = word_class.from_i(10)
        machine.memory[50] = word_class.from_i(20)

        # MUL 50
        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::MUL)
        machine.memory[0] = inst.to_word

        machine.step

        # Result is 200, fits in single word
        # High part (rA) should be 0, low part (rX) should be 200
        expect(machine.registers.a.to_i).to eq(0)
        expect(machine.registers.x.to_i).to eq(200)
      end

      it "handles large products" do
        machine.registers.a = word_class.from_i(1_000_000)
        machine.memory[50] = word_class.from_i(1_000)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::MUL)
        machine.memory[0] = inst.to_word

        machine.step

        # Result is 1,000,000,000 which exceeds one word
        # Should be split across rA (high) and rX (low)
        result = machine.registers.a.to_i * (word_class::MAX_VALUE + 1) + machine.registers.x.to_i
        expect(result).to eq(1_000_000_000)
      end

      it "handles negative multiplication" do
        machine.registers.a = word_class.from_i(-10)
        machine.memory[50] = word_class.from_i(5)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::MUL)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.to_i).to eq(0)
        expect(machine.registers.x.to_i).to eq(-50)
      end
    end

    describe "DIV" do
      it "divides rA:rX by memory value" do
        # For simple division: put value in rX (low word), rA (high word) = 0
        machine.registers.a = word_class.from_i(0)
        machine.registers.x = word_class.from_i(100)
        machine.memory[50] = word_class.from_i(10)

        # DIV 50
        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::DIV)
        machine.memory[0] = inst.to_word

        machine.step

        # Quotient in rA, remainder in rX
        expect(machine.registers.a.to_i).to eq(10)
        expect(machine.registers.x.to_i).to eq(0)
      end

      it "produces remainder" do
        # 25 / 7: put 25 in rX, 0 in rA
        machine.registers.a = word_class.from_i(0)
        machine.registers.x = word_class.from_i(25)
        machine.memory[50] = word_class.from_i(7)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::DIV)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.to_i).to eq(3)   # 25 / 7 = 3
        expect(machine.registers.x.to_i).to eq(4)   # 25 % 7 = 4
      end

      it "handles double-precision dividend" do
        # Dividend = 2 * MAX_VALUE + 1000
        machine.registers.a = word_class.from_i(2)
        machine.registers.x = word_class.from_i(1000)
        machine.memory[50] = word_class.from_i(1000)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::DIV)
        machine.memory[0] = inst.to_word

        machine.step

        # (2 * MAX_VALUE + 1000) / 1000
        dividend = 2 * (word_class::MAX_VALUE + 1) + 1000
        expected_quotient = dividend / 1000
        expected_remainder = dividend % 1000

        expect(machine.registers.a.to_i).to eq(expected_quotient)
        expect(machine.registers.x.to_i).to eq(expected_remainder)
      end

      it "sets overflow on division by zero" do
        machine.registers.a = word_class.from_i(100)
        machine.memory[50] = word_class.from_i(0)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::DIV)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.overflow).to eq(true)
      end
    end
  end

  describe "Complete programs" do
    it "runs a simple arithmetic program" do
      # Program: Load 10, add 20, store result, halt
      # Memory[100] = 10
      # Memory[101] = 20
      # Memory[102] = result location

      machine.memory[100] = word_class.from_i(10)
      machine.memory[101] = word_class.from_i(20)

      # Program at 0-3
      machine.memory[0] = inst_class.new(address: 100, field: 5, opcode: inst_class::LDA).to_word  # LDA 100
      machine.memory[1] = inst_class.new(address: 101, field: 5, opcode: inst_class::ADD).to_word  # ADD 101
      machine.memory[2] = inst_class.new(address: 102, field: 5, opcode: inst_class::STA).to_word  # STA 102
      machine.memory[3] = inst_class.new(opcode: inst_class::HLT, field: 2).to_word                          # HLT

      machine.run

      expect(machine.memory[102].to_i).to eq(30)
      expect(machine.halted).to eq(true)
    end

    it "runs a multiplication program" do
      # Calculate 12 * 5
      machine.memory[100] = word_class.from_i(12)
      machine.memory[101] = word_class.from_i(5)

      machine.memory[0] = inst_class.new(address: 100, field: 5, opcode: inst_class::LDA).to_word  # LDA 100
      machine.memory[1] = inst_class.new(address: 101, field: 5, opcode: inst_class::MUL).to_word  # MUL 101
      machine.memory[2] = inst_class.new(address: 102, field: 5, opcode: inst_class::STX).to_word  # STX 102 (result in X)
      machine.memory[3] = inst_class.new(opcode: inst_class::HLT, field: 2).to_word                          # HLT

      machine.run

      expect(machine.memory[102].to_i).to eq(60)
    end
  end
end
