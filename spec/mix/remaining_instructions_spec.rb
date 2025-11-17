# frozen_string_literal: true

RSpec.describe "MIX Remaining Instructions" do
  let(:machine) { Quackers::Mix::Machine.new }
  let(:inst_class) { Quackers::Mix::Instruction }
  let(:word_class) { Quackers::Mix::Word }

  describe "Shift instructions" do
    describe "SLA - Shift Left A" do
      it "shifts A left by one position" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

        # SLA 1 (shift left by 1)
        inst = inst_class.new(address: 1, field: 0, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Result: [2, 3, 4, 5, 0]
        expect(machine.registers.a.bytes).to eq([2, 3, 4, 5, 0])
      end

      it "shifts A left by two positions" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

        inst = inst_class.new(address: 2, field: 0, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.bytes).to eq([3, 4, 5, 0, 0])
      end

      it "preserves sign during shift" do
        machine.registers.a = word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])

        inst = inst_class.new(address: 1, field: 0, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.sign).to eq(-1)
        expect(machine.registers.a.bytes).to eq([2, 3, 4, 5, 0])
      end

      it "handles shift by 5 (wraps around)" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

        inst = inst_class.new(address: 5, field: 0, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Shifts by 5 mod 5 = 0, so no change... actually shifts by 0
        # Let me check: m % 5 where m = 5 gives 0
        expect(machine.registers.a.bytes).to eq([1, 2, 3, 4, 5])
      end
    end

    describe "SRA - Shift Right A" do
      it "shifts A right by one position" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

        inst = inst_class.new(address: 1, field: 1, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Result: [0, 1, 2, 3, 4]
        expect(machine.registers.a.bytes).to eq([0, 1, 2, 3, 4])
      end

      it "shifts A right by three positions" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

        inst = inst_class.new(address: 3, field: 1, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.bytes).to eq([0, 0, 0, 1, 2])
      end
    end

    describe "SLAX - Shift Left AX" do
      it "shifts A:X left as 10-byte register" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
        machine.registers.x = word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

        inst = inst_class.new(address: 2, field: 2, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Shift 10 bytes [1,2,3,4,5,6,7,8,9,10] left by 2
        # Result: [3,4,5,6,7,8,9,10,0,0]
        expect(machine.registers.a.bytes).to eq([3, 4, 5, 6, 7])
        expect(machine.registers.x.bytes).to eq([8, 9, 10, 0, 0])
      end

      it "preserves signs of both registers" do
        machine.registers.a = word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
        machine.registers.x = word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

        inst = inst_class.new(address: 1, field: 2, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.a.sign).to eq(-1)
        expect(machine.registers.x.sign).to eq(1)
      end
    end

    describe "SRAX - Shift Right AX" do
      it "shifts A:X right as 10-byte register" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
        machine.registers.x = word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

        inst = inst_class.new(address: 3, field: 3, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Shift 10 bytes [1,2,3,4,5,6,7,8,9,10] right by 3
        # Result: [0,0,0,1,2,3,4,5,6,7]
        expect(machine.registers.a.bytes).to eq([0, 0, 0, 1, 2])
        expect(machine.registers.x.bytes).to eq([3, 4, 5, 6, 7])
      end
    end

    describe "SLC - Shift Left Circular" do
      it "rotates A:X left" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
        machine.registers.x = word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

        inst = inst_class.new(address: 2, field: 4, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Rotate [1,2,3,4,5,6,7,8,9,10] left by 2
        # Result: [3,4,5,6,7,8,9,10,1,2]
        expect(machine.registers.a.bytes).to eq([3, 4, 5, 6, 7])
        expect(machine.registers.x.bytes).to eq([8, 9, 10, 1, 2])
      end

      it "handles full rotation" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
        machine.registers.x = word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

        inst = inst_class.new(address: 10, field: 4, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Rotate by 10 (full cycle) = no change
        expect(machine.registers.a.bytes).to eq([1, 2, 3, 4, 5])
        expect(machine.registers.x.bytes).to eq([6, 7, 8, 9, 10])
      end
    end

    describe "SRC - Shift Right Circular" do
      it "rotates A:X right" do
        machine.registers.a = word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
        machine.registers.x = word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

        inst = inst_class.new(address: 3, field: 5, opcode: 6)
        machine.memory[0] = inst.to_word

        machine.step

        # Rotate [1,2,3,4,5,6,7,8,9,10] right by 3
        # Result: [8,9,10,1,2,3,4,5,6,7]
        expect(machine.registers.a.bytes).to eq([8, 9, 10, 1, 2])
        expect(machine.registers.x.bytes).to eq([3, 4, 5, 6, 7])
      end
    end
  end

  describe "MOVE instruction" do
    it "moves F words from M to location in I1" do
      # Setup source data at locations 100-102
      machine.memory[100] = word_class.from_i(10)
      machine.memory[101] = word_class.from_i(20)
      machine.memory[102] = word_class.from_i(30)

      # Set I1 to destination address 200
      machine.registers.set_index_i(1, 200)

      # MOVE 100(3) - move 3 words from 100 to I1
      inst = inst_class.new(address: 100, field: 3, opcode: 7)
      machine.memory[0] = inst.to_word

      machine.step

      # Check data was moved
      expect(machine.memory[200].to_i).to eq(10)
      expect(machine.memory[201].to_i).to eq(20)
      expect(machine.memory[202].to_i).to eq(30)

      # Check I1 was updated
      expect(machine.registers.get_index_i(1)).to eq(203)
    end

    it "handles moving 0 words" do
      machine.registers.set_index_i(1, 100)

      inst = inst_class.new(address: 200, field: 0, opcode: 7)
      machine.memory[0] = inst.to_word

      machine.step

      # I1 should still be updated (100 + 0 = 100)
      expect(machine.registers.get_index_i(1)).to eq(100)
    end

    it "can move to overlapping locations" do
      machine.memory[100] = word_class.from_i(1)
      machine.memory[101] = word_class.from_i(2)
      machine.memory[102] = word_class.from_i(3)

      machine.registers.set_index_i(1, 101)

      # Move from 100 to 101 (overlapping)
      # Word-by-word copy means: mem[101]=mem[100], then mem[102]=mem[101]
      # So mem[102] ends up with the value that was in mem[100] (1, not 2)
      inst = inst_class.new(address: 100, field: 2, opcode: 7)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.memory[101].to_i).to eq(1)
      expect(machine.memory[102].to_i).to eq(1)  # Gets copy of mem[101], which is now 1
    end
  end

  describe "NUM instruction" do
    it "converts character digits to numeric value" do
      # Setup A:X with character representation of "0000012345"
      # MIX chars 30-39 represent digits 0-9
      machine.registers.a = word_class.new(sign: 1, bytes: [30, 30, 30, 30, 30])  # "00000"
      machine.registers.x = word_class.new(sign: 1, bytes: [31, 32, 33, 34, 35])  # "12345"

      # NUM instruction
      inst = inst_class.new(field: 0, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(12345)
    end

    it "handles negative sign" do
      machine.registers.a = word_class.new(sign: -1, bytes: [30, 30, 30, 30, 30])
      machine.registers.x = word_class.new(sign: -1, bytes: [31, 32, 33, 34, 35])

      inst = inst_class.new(field: 0, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(-12345)
    end

    it "handles all zeros" do
      machine.registers.a = word_class.new(sign: 1, bytes: [30, 30, 30, 30, 30])
      machine.registers.x = word_class.new(sign: 1, bytes: [30, 30, 30, 30, 30])

      inst = inst_class.new(field: 0, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(0)
    end

    it "treats non-digit characters as 0" do
      # Mix some non-digit characters (like 1 = 'A')
      machine.registers.a = word_class.new(sign: 1, bytes: [30, 1, 30, 2, 30])
      machine.registers.x = word_class.new(sign: 1, bytes: [31, 32, 33, 34, 35])

      inst = inst_class.new(field: 0, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      # "0A0B012345" -> 0000012345 = 12345
      expect(machine.registers.a.to_i).to eq(12345)
    end
  end

  describe "CHAR instruction" do
    it "converts numeric value to character representation" do
      machine.registers.a = word_class.from_i(12345)

      # CHAR instruction
      inst = inst_class.new(field: 1, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      # Should produce "0000012345"
      expect(machine.registers.a.bytes).to eq([30, 30, 30, 30, 30])  # "00000"
      expect(machine.registers.x.bytes).to eq([31, 32, 33, 34, 35])  # "12345"
    end

    it "preserves sign" do
      machine.registers.a = word_class.from_i(-12345)

      inst = inst_class.new(field: 1, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.sign).to eq(-1)
      expect(machine.registers.x.sign).to eq(-1)
      # Bytes represent absolute value
      expect(machine.registers.a.bytes).to eq([30, 30, 30, 30, 30])
      expect(machine.registers.x.bytes).to eq([31, 32, 33, 34, 35])
    end

    it "handles zero" do
      machine.registers.a = word_class.from_i(0)

      inst = inst_class.new(field: 1, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      # "0000000000"
      expect(machine.registers.a.bytes).to eq([30, 30, 30, 30, 30])
      expect(machine.registers.x.bytes).to eq([30, 30, 30, 30, 30])
    end

    it "handles large numbers" do
      # Use max value that fits: 1073741823
      machine.registers.a = word_class.from_i(1073741823)

      inst = inst_class.new(field: 1, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      # "1073741823"
      expect(machine.registers.a.bytes).to eq([31, 30, 37, 33, 37])  # "10737"
      expect(machine.registers.x.bytes).to eq([34, 31, 38, 32, 33])  # "41823"
    end
  end

  describe "NUM and CHAR round-trip" do
    it "converts number to char and back" do
      original = 123456789
      machine.registers.a = word_class.from_i(original)

      # CHAR
      char_inst = inst_class.new(field: 1, opcode: 5)
      machine.memory[0] = char_inst.to_word
      machine.step

      # NUM
      num_inst = inst_class.new(field: 0, opcode: 5)
      machine.memory[1] = num_inst.to_word
      machine.step

      expect(machine.registers.a.to_i).to eq(original)
    end
  end

  describe "HLT instruction with field specification" do
    it "still halts when using field 2" do
      # Verify HLT works with proper field specification
      inst = inst_class.new(field: 2, opcode: 5)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.halted).to eq(true)
    end
  end
end
