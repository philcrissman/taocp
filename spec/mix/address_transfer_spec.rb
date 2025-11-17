# frozen_string_literal: true

RSpec.describe "MIX Address Transfer Instructions" do
  let(:machine) { Quackers::Mix::Machine.new }
  let(:inst_class) { Quackers::Mix::Instruction }
  let(:word_class) { Quackers::Mix::Word }

  describe "ENT - Enter register" do
    it "ENTA sets A register to immediate value" do
      # ENTA 100 (field=0 for ENT)
      inst = inst_class.new(address: 100, field: 0, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(100)
    end

    it "ENTX sets X register" do
      inst = inst_class.new(address: 50, field: 0, opcode: 55)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.x.to_i).to eq(50)
    end

    it "ENT1-ENT6 set index registers" do
      (1..6).each do |i|
        machine.reset
        # ENTi with value = i * 10
        inst = inst_class.new(address: i * 10, field: 0, opcode: 48 + i)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.get_index_i(i)).to eq(i * 10)
      end
    end

    it "ENT can use index register for address calculation" do
      machine.registers.set_index_i(1, 50)
      # ENTA 100,1 -> enters 100 + I1 = 150
      inst = inst_class.new(address: 100, index: 1, field: 0, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(150)
    end
  end

  describe "ENN - Enter negative" do
    it "ENNA sets A to negative of immediate value" do
      inst = inst_class.new(address: 75, field: 1, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(-75)
    end

    it "ENNX sets X to negative" do
      inst = inst_class.new(address: 25, field: 1, opcode: 55)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.x.to_i).to eq(-25)
    end

    it "ENN1 sets index register to negative" do
      inst = inst_class.new(address: 10, field: 1, opcode: 49)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.get_index_i(1)).to eq(-10)
    end
  end

  describe "INC - Increment register" do
    it "INCA increments A register" do
      machine.registers.a = word_class.from_i(100)

      # INCA 25
      inst = inst_class.new(address: 25, field: 2, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(125)
    end

    it "INCX increments X register" do
      machine.registers.x = word_class.from_i(50)

      inst = inst_class.new(address: 10, field: 2, opcode: 55)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.x.to_i).to eq(60)
    end

    it "INC1 increments index register" do
      machine.registers.set_index_i(1, 100)

      inst = inst_class.new(address: 5, field: 2, opcode: 49)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.get_index_i(1)).to eq(105)
    end

    it "INC by large value" do
      machine.registers.a = word_class.from_i(100)

      # INCA 500
      inst = inst_class.new(address: 500, field: 2, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(600)
    end

    it "INC sets overflow on overflow" do
      machine.registers.a = word_class.from_i(word_class::MAX_VALUE)

      inst = inst_class.new(address: 1, field: 2, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.overflow).to eq(true)
    end
  end

  describe "DEC - Decrement register" do
    it "DECA decrements A register" do
      machine.registers.a = word_class.from_i(100)

      # DECA 30
      inst = inst_class.new(address: 30, field: 3, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(70)
    end

    it "DECX decrements X register" do
      machine.registers.x = word_class.from_i(50)

      inst = inst_class.new(address: 10, field: 3, opcode: 55)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.x.to_i).to eq(40)
    end

    it "DEC1 decrements index register" do
      machine.registers.set_index_i(1, 100)

      inst = inst_class.new(address: 25, field: 3, opcode: 49)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.get_index_i(1)).to eq(75)
    end

    it "DEC can produce negative results" do
      machine.registers.a = word_class.from_i(10)

      # DECA 50
      inst = inst_class.new(address: 50, field: 3, opcode: 48)
      machine.memory[0] = inst.to_word

      machine.step

      expect(machine.registers.a.to_i).to eq(-40)
    end
  end

  describe "Array indexing patterns" do
    it "uses index register to access array elements" do
      # Set up an array in memory at locations 100-104
      (0..4).each do |i|
        machine.memory[100 + i] = word_class.from_i((i + 1) * 10)
      end

      # Program: Sum array elements using index register
      # Memory[200] = sum (result)
      # I1 = array index (0 to 4)

      machine.memory[200] = word_class.from_i(0)  # sum = 0

      # ENT1 0 - Initialize index to 0
      machine.memory[0] = inst_class.new(address: 0, field: 0, opcode: 49).to_word

      # Loop start (address 1)
      # LDA 200 - Load current sum
      machine.memory[1] = inst_class.new(address: 200, field: 5, opcode: inst_class::LDA).to_word

      # ADD 100,1 - Add array[i] (100 + I1)
      machine.memory[2] = inst_class.new(address: 100, index: 1, field: 5, opcode: inst_class::ADD).to_word

      # STA 200 - Store sum
      machine.memory[3] = inst_class.new(address: 200, field: 5, opcode: inst_class::STA).to_word

      # INC1 1 - Increment index
      machine.memory[4] = inst_class.new(address: 1, field: 2, opcode: 49).to_word

      # CMP1 5 - Compare index with 5
      machine.memory[5] = inst_class.new(address: 205, field: 5, opcode: inst_class::CMP1).to_word
      machine.memory[205] = word_class.from_i(5)

      # JL 1 - Jump to loop start if less
      machine.memory[6] = inst_class.new(address: 1, field: 4, opcode: inst_class::JMP).to_word

      # HLT
      machine.memory[7] = inst_class.new(opcode: inst_class::HLT).to_word

      machine.run

      # Sum should be 10 + 20 + 30 + 40 + 50 = 150
      expect(machine.memory[200].to_i).to eq(150)
      expect(machine.halted).to eq(true)
    end

    it "finds maximum element in array using index register" do
      # Array at 100-104: 15, 42, 8, 99, 23
      machine.memory[100] = word_class.from_i(15)
      machine.memory[101] = word_class.from_i(42)
      machine.memory[102] = word_class.from_i(8)
      machine.memory[103] = word_class.from_i(99)
      machine.memory[104] = word_class.from_i(23)

      # Result at 200
      machine.memory[200] = word_class.from_i(0)  # max

      # ENT1 0 - index = 0
      machine.memory[0] = inst_class.new(address: 0, field: 0, opcode: 49).to_word

      # LDA 100 - Load first element as initial max
      machine.memory[1] = inst_class.new(address: 100, field: 5, opcode: inst_class::LDA).to_word

      # STA 200 - Store as max
      machine.memory[2] = inst_class.new(address: 200, field: 5, opcode: inst_class::STA).to_word

      # Loop: check rest of array
      # INC1 1 - Move to next element
      machine.memory[3] = inst_class.new(address: 1, field: 2, opcode: 49).to_word

      # CMPA 100,1 - Compare max with current element
      machine.memory[4] = inst_class.new(address: 100, index: 1, field: 5, opcode: inst_class::CMPA).to_word

      # JGE 7 - If max >= current, skip update
      machine.memory[5] = inst_class.new(address: 7, field: 7, opcode: inst_class::JMP).to_word

      # LDA 100,1 - Load new max
      machine.memory[6] = inst_class.new(address: 100, index: 1, field: 5, opcode: inst_class::LDA).to_word

      # STA 200 - Store new max (address 7)
      machine.memory[7] = inst_class.new(address: 200, field: 5, opcode: inst_class::STA).to_word

      # CMP1 constant 4 - Are we done?
      machine.memory[8] = inst_class.new(address: 210, field: 5, opcode: inst_class::CMP1).to_word
      machine.memory[210] = word_class.from_i(4)

      # JL 3 - Loop if index < 4
      machine.memory[9] = inst_class.new(address: 3, field: 4, opcode: inst_class::JMP).to_word

      # HLT
      machine.memory[10] = inst_class.new(opcode: inst_class::HLT).to_word

      machine.run

      expect(machine.memory[200].to_i).to eq(99)  # Maximum is 99
      expect(machine.halted).to eq(true)
    end

    it "copies array using two index registers" do
      # Source array at 100-102
      machine.memory[100] = word_class.from_i(10)
      machine.memory[101] = word_class.from_i(20)
      machine.memory[102] = word_class.from_i(30)

      # ENT1 0 - source index
      machine.memory[0] = inst_class.new(address: 0, field: 0, opcode: 49).to_word

      # ENT2 0 - dest index
      machine.memory[1] = inst_class.new(address: 0, field: 0, opcode: 50).to_word

      # Loop (address 2)
      # LDA 100,1 - Load from source
      machine.memory[2] = inst_class.new(address: 100, index: 1, field: 5, opcode: inst_class::LDA).to_word

      # STA 200,2 - Store to dest (200 + I2)
      machine.memory[3] = inst_class.new(address: 200, index: 2, field: 5, opcode: inst_class::STA).to_word

      # INC1 1
      machine.memory[4] = inst_class.new(address: 1, field: 2, opcode: 49).to_word

      # INC2 1
      machine.memory[5] = inst_class.new(address: 1, field: 2, opcode: 50).to_word

      # CMP1 3
      machine.memory[6] = inst_class.new(address: 300, field: 5, opcode: inst_class::CMP1).to_word
      machine.memory[300] = word_class.from_i(3)

      # JL 2
      machine.memory[7] = inst_class.new(address: 2, field: 4, opcode: inst_class::JMP).to_word

      # HLT
      machine.memory[8] = inst_class.new(opcode: inst_class::HLT).to_word

      machine.run

      # Check copied array
      expect(machine.memory[200].to_i).to eq(10)
      expect(machine.memory[201].to_i).to eq(20)
      expect(machine.memory[202].to_i).to eq(30)
    end
  end

  describe "Loop counter patterns" do
    it "uses DEC for counting down" do
      # Traditional countdown loop using DEC

      # ENT1 10 - counter = 10
      machine.memory[0] = inst_class.new(address: 10, field: 0, opcode: 49).to_word

      # Loop (address 1)
      # DEC1 1 - Decrement counter
      machine.memory[1] = inst_class.new(address: 1, field: 3, opcode: 49).to_word

      # J1P 1 - Jump if I1 > 0
      # For this we need to compare and jump
      # CMP1 0
      machine.memory[2] = inst_class.new(address: 400, field: 5, opcode: inst_class::CMP1).to_word
      machine.memory[400] = word_class.from_i(0)

      # JG 1
      machine.memory[3] = inst_class.new(address: 1, field: 6, opcode: inst_class::JMP).to_word

      # HLT
      machine.memory[4] = inst_class.new(opcode: inst_class::HLT).to_word

      machine.run

      expect(machine.registers.get_index_i(1)).to eq(0)
      expect(machine.halted).to eq(true)
    end
  end
end
