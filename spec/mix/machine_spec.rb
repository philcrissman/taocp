# frozen_string_literal: true

RSpec.describe Quackers::Mix::Machine do
  let(:machine) { described_class.new }

  describe "initialization" do
    it "creates a new machine with initialized state" do
      expect(machine.memory).to be_a(Quackers::Mix::Memory)
      expect(machine.registers).to be_a(Quackers::Mix::Registers)
      expect(machine.pc).to eq(0)
      expect(machine.halted).to eq(false)
    end

    it "initializes memory with zero words" do
      expect(machine.memory[0].to_i).to eq(0)
      expect(machine.memory[100].to_i).to eq(0)
      expect(machine.memory[3999].to_i).to eq(0)
    end

    it "initializes all registers to zero" do
      expect(machine.registers.a.to_i).to eq(0)
      expect(machine.registers.x.to_i).to eq(0)
      (1..6).each do |i|
        expect(machine.registers.get_index(i).to_i).to eq(0)
      end
      expect(machine.registers.j).to eq(0)
    end
  end

  describe "#reset" do
    it "resets machine to initial state" do
      # Modify machine state
      machine.memory[100] = Quackers::Mix::Word.from_i(42)
      machine.registers.a = Quackers::Mix::Word.from_i(99)
      machine.instance_variable_set(:@pc, 50)
      machine.halted = true

      # Reset
      machine.reset

      # Verify reset
      expect(machine.memory[100].to_i).to eq(0)
      expect(machine.registers.a.to_i).to eq(0)
      expect(machine.pc).to eq(0)
      expect(machine.halted).to eq(false)
    end
  end

  describe "memory access" do
    it "allows reading and writing memory" do
      word = Quackers::Mix::Word.from_i(12345)
      machine.memory[500] = word

      expect(machine.memory[500].to_i).to eq(12345)
    end

    it "maintains separate memory locations" do
      machine.memory[0] = Quackers::Mix::Word.from_i(1)
      machine.memory[1] = Quackers::Mix::Word.from_i(2)
      machine.memory[2] = Quackers::Mix::Word.from_i(3)

      expect(machine.memory[0].to_i).to eq(1)
      expect(machine.memory[1].to_i).to eq(2)
      expect(machine.memory[2].to_i).to eq(3)
    end
  end

  describe "register access" do
    it "allows setting and getting register A" do
      word = Quackers::Mix::Word.from_i(100)
      machine.registers.a = word
      expect(machine.registers.a.to_i).to eq(100)
    end

    it "allows setting and getting register X" do
      word = Quackers::Mix::Word.from_i(200)
      machine.registers.x = word
      expect(machine.registers.x.to_i).to eq(200)
    end

    it "allows setting and getting index registers" do
      (1..6).each do |i|
        machine.registers.set_index_i(i, i * 10)
        expect(machine.registers.get_index_i(i)).to eq(i * 10)
      end
    end

    it "sets comparison flag" do
      machine.registers.comparison_flag = :greater
      expect(machine.registers.comparison_flag).to eq(:greater)
    end

    it "sets overflow flag" do
      machine.registers.overflow = true
      expect(machine.registers.overflow).to eq(true)
    end
  end

  describe "instruction execution" do
    describe "HLT instruction" do
      it "halts the machine" do
        # Create HLT instruction at memory[0]
        hlt_inst = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::HLT, field: 2)
        machine.memory[0] = hlt_inst.to_word

        machine.step

        expect(machine.halted).to eq(true)
        expect(machine.pc).to eq(1)
      end
    end

    describe "NOP instruction" do
      it "does nothing but advances PC" do
        nop_inst = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::NOP)
        machine.memory[0] = nop_inst.to_word

        machine.step

        expect(machine.pc).to eq(1)
        expect(machine.halted).to eq(false)
      end
    end

    describe "#step" do
      it "fetches, decodes, and executes one instruction" do
        # Put two NOPs and a HLT
        nop = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::NOP).to_word
        hlt = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::HLT, field: 2).to_word

        machine.memory[0] = nop
        machine.memory[1] = nop
        machine.memory[2] = hlt

        machine.step
        expect(machine.pc).to eq(1)
        expect(machine.halted).to eq(false)

        machine.step
        expect(machine.pc).to eq(2)
        expect(machine.halted).to eq(false)

        machine.step
        expect(machine.pc).to eq(3)
        expect(machine.halted).to eq(true)
      end

      it "does nothing if already halted" do
        machine.halted = true
        machine.pc = 5

        machine.step

        expect(machine.pc).to eq(5)  # Unchanged
      end
    end

    describe "#run" do
      it "runs until HLT" do
        # Create a simple program: 3 NOPs then HLT
        nop = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::NOP).to_word
        hlt = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::HLT, field: 2).to_word

        machine.memory[0] = nop
        machine.memory[1] = nop
        machine.memory[2] = nop
        machine.memory[3] = hlt

        count = machine.run

        expect(machine.halted).to eq(true)
        expect(machine.pc).to eq(4)
        expect(count).to eq(4)
      end

      it "stops after MAX_INSTRUCTIONS to prevent infinite loops" do
        # Create a program that runs past the limit
        # We'll fill memory with enough NOPs that it would exceed MAX_INSTRUCTIONS
        nop = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::NOP).to_word
        # Fill first 1000 locations with NOPs (more than enough to hit limit)
        (0...1000).each { |i| machine.memory[i] = nop }

        # Override MAX_INSTRUCTIONS temporarily for faster test
        original_max = Quackers::Mix::Machine::MAX_INSTRUCTIONS
        Quackers::Mix::Machine.const_set(:MAX_INSTRUCTIONS, 500)

        # Should raise after 500 instructions
        expect { machine.run }.to raise_error(Quackers::Mix::Error, /Instruction limit exceeded/)

        # Restore original
        Quackers::Mix::Machine.const_set(:MAX_INSTRUCTIONS, original_max)
      end

      it "returns instruction count" do
        nop = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::NOP).to_word
        hlt = Quackers::Mix::Instruction.new(opcode: Quackers::Mix::Instruction::HLT, field: 2).to_word

        machine.memory[0] = nop
        machine.memory[1] = nop
        machine.memory[2] = hlt

        count = machine.run
        expect(count).to eq(3)
        expect(machine.instruction_count).to eq(3)
      end
    end
  end
end

RSpec.describe Quackers::Mix::Registers do
  let(:registers) { described_class.new }

  describe "#get_index and #set_index" do
    it "gets and sets index register by number" do
      word = Quackers::Mix::Word.from_i(42)
      registers.set_index(3, word)
      expect(registers.get_index(3).to_i).to eq(42)
    end

    it "raises error for invalid index number" do
      expect { registers.get_index(0) }.to raise_error(Quackers::Mix::Error)
      expect { registers.get_index(7) }.to raise_error(Quackers::Mix::Error)
      expect { registers.set_index(0, Quackers::Mix::Word.new) }.to raise_error(Quackers::Mix::Error)
    end
  end

  describe "#set_index_i and #get_index_i" do
    it "sets index register from integer" do
      registers.set_index_i(1, 100)
      expect(registers.get_index_i(1)).to eq(100)
    end

    it "handles negative values" do
      registers.set_index_i(2, -50)
      expect(registers.get_index_i(2)).to eq(-50)
    end

    it "raises error for values exceeding 2-byte capacity" do
      expect { registers.set_index_i(1, 5000) }.to raise_error(ArgumentError, /out of range/)
      expect { registers.set_index_i(1, -5000) }.to raise_error(ArgumentError, /out of range/)
    end

    it "handles maximum valid values" do
      registers.set_index_i(1, 4095)
      expect(registers.get_index_i(1)).to eq(4095)

      registers.set_index_i(2, -4095)
      expect(registers.get_index_i(2)).to eq(-4095)
    end
  end
end

RSpec.describe Quackers::Mix::Memory do
  let(:memory) { described_class.new }

  describe "initialization" do
    it "creates 4000 words of memory" do
      expect(memory[0]).to be_a(Quackers::Mix::Word)
      expect(memory[3999]).to be_a(Quackers::Mix::Word)
    end

    it "initializes all memory to zero" do
      expect(memory[0].to_i).to eq(0)
      expect(memory[1000].to_i).to eq(0)
      expect(memory[3999].to_i).to eq(0)
    end
  end

  describe "bounds checking" do
    it "raises error for negative address" do
      expect { memory[-1] }.to raise_error(Quackers::Mix::Error, /Invalid memory address/)
    end

    it "raises error for address >= 4000" do
      expect { memory[4000] }.to raise_error(Quackers::Mix::Error, /Invalid memory address/)
      expect { memory[5000] }.to raise_error(Quackers::Mix::Error, /Invalid memory address/)
    end

    it "allows valid addresses 0..3999" do
      expect { memory[0] }.not_to raise_error
      expect { memory[3999] }.not_to raise_error
    end
  end

  describe "storage and retrieval" do
    it "stores and retrieves words correctly" do
      word = Quackers::Mix::Word.from_i(12345)
      memory[100] = word
      expect(memory[100].to_i).to eq(12345)
    end

    it "maintains independent storage locations" do
      memory[0] = Quackers::Mix::Word.from_i(1)
      memory[1] = Quackers::Mix::Word.from_i(2)
      expect(memory[0].to_i).to eq(1)
      expect(memory[1].to_i).to eq(2)
    end
  end
end
