# frozen_string_literal: true

RSpec.describe "MIX Comparison and Jump Instructions" do
  let(:machine) { Quackers::Mix::Machine.new }
  let(:inst_class) { Quackers::Mix::Instruction }
  let(:word_class) { Quackers::Mix::Word }

  describe "Comparison instructions" do
    describe "CMPA" do
      it "sets comparison flag to :less when A < memory" do
        machine.registers.a = word_class.from_i(10)
        machine.memory[100] = word_class.from_i(20)

        inst = inst_class.new(address: 100, field: 5, opcode: inst_class::CMPA)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.comparison_flag).to eq(:less)
      end

      it "sets comparison flag to :equal when A == memory" do
        machine.registers.a = word_class.from_i(15)
        machine.memory[100] = word_class.from_i(15)

        inst = inst_class.new(address: 100, field: 5, opcode: inst_class::CMPA)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.comparison_flag).to eq(:equal)
      end

      it "sets comparison flag to :greater when A > memory" do
        machine.registers.a = word_class.from_i(30)
        machine.memory[100] = word_class.from_i(10)

        inst = inst_class.new(address: 100, field: 5, opcode: inst_class::CMPA)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.comparison_flag).to eq(:greater)
      end

      it "handles negative numbers" do
        machine.registers.a = word_class.from_i(-5)
        machine.memory[100] = word_class.from_i(10)

        inst = inst_class.new(address: 100, field: 5, opcode: inst_class::CMPA)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.comparison_flag).to eq(:less)
      end
    end

    describe "CMPX" do
      it "compares register X with memory" do
        machine.registers.x = word_class.from_i(100)
        machine.memory[50] = word_class.from_i(50)

        inst = inst_class.new(address: 50, field: 5, opcode: inst_class::CMPX)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.comparison_flag).to eq(:greater)
      end
    end

    describe "CMP1-CMP6" do
      it "compares index registers" do
        machine.registers.set_index_i(1, 42)
        machine.memory[100] = word_class.from_i(42)

        inst = inst_class.new(address: 100, field: 5, opcode: inst_class::CMP1)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.registers.comparison_flag).to eq(:equal)
      end
    end
  end

  describe "Jump instructions" do
    describe "JMP - unconditional jump" do
      it "jumps to address and saves return address in J" do
        # JMP 200 (field=0 for unconditional)
        inst = inst_class.new(address: 200, field: 0, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(200)
        expect(machine.registers.j).to eq(1)  # Return address (PC after fetch)
      end
    end

    describe "JSJ - jump without saving J" do
      it "jumps but doesn't modify J register" do
        machine.registers.j = 999

        inst = inst_class.new(address: 300, field: 1, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(300)
        expect(machine.registers.j).to eq(999)  # Unchanged
      end
    end

    describe "JOV - jump on overflow" do
      it "jumps when overflow is set" do
        machine.registers.overflow = true

        inst = inst_class.new(address: 100, field: 2, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(100)
        expect(machine.registers.overflow).to eq(false)  # Reset after jump
      end

      it "doesn't jump when overflow is not set" do
        machine.registers.overflow = false

        inst = inst_class.new(address: 100, field: 2, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(1)  # No jump
      end
    end

    describe "JL - jump if less" do
      it "jumps when comparison flag is :less" do
        machine.registers.comparison_flag = :less

        inst = inst_class.new(address: 150, field: 4, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(150)
      end

      it "doesn't jump when comparison flag is not :less" do
        machine.registers.comparison_flag = :equal

        inst = inst_class.new(address: 150, field: 4, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(1)
      end
    end

    describe "JE - jump if equal" do
      it "jumps when comparison flag is :equal" do
        machine.registers.comparison_flag = :equal

        inst = inst_class.new(address: 200, field: 5, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(200)
      end
    end

    describe "JG - jump if greater" do
      it "jumps when comparison flag is :greater" do
        machine.registers.comparison_flag = :greater

        inst = inst_class.new(address: 250, field: 6, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(250)
      end
    end

    describe "JGE - jump if greater or equal" do
      it "jumps when comparison flag is :greater" do
        machine.registers.comparison_flag = :greater

        inst = inst_class.new(address: 300, field: 7, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(300)
      end

      it "jumps when comparison flag is :equal" do
        machine.registers.comparison_flag = :equal

        inst = inst_class.new(address: 300, field: 7, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(300)
      end

      it "doesn't jump when comparison flag is :less" do
        machine.registers.comparison_flag = :less

        inst = inst_class.new(address: 300, field: 7, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(1)
      end
    end

    describe "JNE - jump if not equal" do
      it "jumps when comparison flag is not :equal" do
        machine.registers.comparison_flag = :less

        inst = inst_class.new(address: 400, field: 8, opcode: inst_class::JMP)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(400)
      end
    end

    describe "JLE - jump if less or equal" do
      it "jumps when comparison flag is :less or :equal" do
        [:less, :equal].each do |flag|
          machine.reset
          machine.registers.comparison_flag = flag

          inst = inst_class.new(address: 500, field: 9, opcode: inst_class::JMP)
          machine.memory[0] = inst.to_word

          machine.step

          expect(machine.pc).to eq(500)
        end
      end
    end
  end

  describe "JAN - Jump on A conditions" do
    describe "JAN - jump if A negative" do
      it "jumps when A is negative" do
        machine.registers.a = word_class.from_i(-10)

        inst = inst_class.new(address: 100, field: 0, opcode: inst_class::JAN)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(100)
      end

      it "doesn't jump when A is positive or zero" do
        [0, 10].each do |value|
          machine.reset
          machine.registers.a = word_class.from_i(value)

          inst = inst_class.new(address: 100, field: 0, opcode: inst_class::JAN)
          machine.memory[0] = inst.to_word

          machine.step

          expect(machine.pc).to eq(1)
        end
      end
    end

    describe "JAZ - jump if A zero" do
      it "jumps when A is zero" do
        machine.registers.a = word_class.from_i(0)

        inst = inst_class.new(address: 200, field: 1, opcode: inst_class::JAN)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(200)
      end
    end

    describe "JAP - jump if A positive" do
      it "jumps when A is positive" do
        machine.registers.a = word_class.from_i(5)

        inst = inst_class.new(address: 300, field: 2, opcode: inst_class::JAN)
        machine.memory[0] = inst.to_word

        machine.step

        expect(machine.pc).to eq(300)
      end
    end

    describe "JANN - jump if A non-negative" do
      it "jumps when A is zero or positive" do
        [0, 10].each do |value|
          machine.reset
          machine.registers.a = word_class.from_i(value)

          inst = inst_class.new(address: 400, field: 3, opcode: inst_class::JAN)
          machine.memory[0] = inst.to_word

          machine.step

          expect(machine.pc).to eq(400)
        end
      end
    end

    describe "JANZ - jump if A non-zero" do
      it "jumps when A is not zero" do
        [-5, 5].each do |value|
          machine.reset
          machine.registers.a = word_class.from_i(value)

          inst = inst_class.new(address: 500, field: 4, opcode: inst_class::JAN)
          machine.memory[0] = inst.to_word

          machine.step

          expect(machine.pc).to eq(500)
        end
      end
    end

    describe "JANP - jump if A non-positive" do
      it "jumps when A is zero or negative" do
        [0, -10].each do |value|
          machine.reset
          machine.registers.a = word_class.from_i(value)

          inst = inst_class.new(address: 600, field: 5, opcode: inst_class::JAN)
          machine.memory[0] = inst.to_word

          machine.step

          expect(machine.pc).to eq(600)
        end
      end
    end
  end

  describe "Loop programs" do
    it "counts down from 10 to 0 using a loop" do
      # Program: Initialize counter to 10, decrement, loop until zero
      # Memory layout:
      # [100] = counter (initial value 10)
      # [101] = decrement value (-1)
      # [0-4] = program

      machine.memory[100] = word_class.from_i(10)
      machine.memory[101] = word_class.from_i(-1)

      # Program:
      # 0: LDA 100      - Load counter into A
      # 1: ADD 101      - Add -1 (decrement)
      # 2: STA 100      - Store back to counter
      # 3: JAP 0        - Jump to 0 if A is positive
      # 4: HLT          - Halt when counter reaches 0

      machine.memory[0] = inst_class.new(address: 100, field: 5, opcode: inst_class::LDA).to_word
      machine.memory[1] = inst_class.new(address: 101, field: 5, opcode: inst_class::ADD).to_word
      machine.memory[2] = inst_class.new(address: 100, field: 5, opcode: inst_class::STA).to_word
      machine.memory[3] = inst_class.new(address: 0, field: 2, opcode: inst_class::JAN).to_word  # JAP
      machine.memory[4] = inst_class.new(opcode: inst_class::HLT, field: 2).to_word

      count = machine.run

      # Should have executed: 10 iterations * 4 instructions + 1 final HLT
      # Each iteration: LDA, ADD, STA, JAP (4 instructions)
      # Last iteration: LDA, ADD, STA, JAP (doesn't jump), HLT
      expect(machine.memory[100].to_i).to eq(0)
      expect(machine.halted).to eq(true)
      expect(machine.registers.a.to_i).to eq(0)
    end

    it "calculates factorial of 5 using a loop" do
      # Calculate 5! = 120
      # Memory layout:
      # [100] = n (5)
      # [101] = result (accumulated product, starts at 1)
      # [102] = constant 1

      machine.memory[100] = word_class.from_i(5)     # n
      machine.memory[101] = word_class.from_i(1)     # result = 1
      machine.memory[102] = word_class.from_i(-1)    # decrement

      # Program:
      # 0: LDA 101      - Load result
      # 1: MUL 100      - Multiply by n
      # 2: STX 101      - Store result (MUL result is in rX)
      # 3: LDA 100      - Load n
      # 4: ADD 102      - Decrement n
      # 5: STA 100      - Store n
      # 6: JAP 0        - If n > 0, loop
      # 7: HLT

      machine.memory[0] = inst_class.new(address: 101, field: 5, opcode: inst_class::LDA).to_word
      machine.memory[1] = inst_class.new(address: 100, field: 5, opcode: inst_class::MUL).to_word
      machine.memory[2] = inst_class.new(address: 101, field: 5, opcode: inst_class::STX).to_word
      machine.memory[3] = inst_class.new(address: 100, field: 5, opcode: inst_class::LDA).to_word
      machine.memory[4] = inst_class.new(address: 102, field: 5, opcode: inst_class::ADD).to_word
      machine.memory[5] = inst_class.new(address: 100, field: 5, opcode: inst_class::STA).to_word
      machine.memory[6] = inst_class.new(address: 0, field: 2, opcode: inst_class::JAN).to_word  # JAP
      machine.memory[7] = inst_class.new(opcode: inst_class::HLT, field: 2).to_word

      machine.run

      expect(machine.memory[101].to_i).to eq(120)  # 5! = 120
      expect(machine.halted).to eq(true)
    end

    it "uses comparison and conditional jump" do
      # Find if 15 is less than, equal to, or greater than 20
      machine.memory[100] = word_class.from_i(15)
      machine.memory[101] = word_class.from_i(20)

      # Program:
      # 0: LDA 100      - Load first number
      # 1: CMPA 101     - Compare with second number
      # 2: JL 10        - Jump to 10 if less
      # 3: JE 20        - Jump to 20 if equal
      # 4: JG 30        - Jump to 30 if greater
      # 10: LDA constant 1 (less)
      # 11: STA 200
      # 12: HLT
      # 20: LDA constant 2 (equal)
      # 21: STA 200
      # 22: HLT
      # 30: LDA constant 3 (greater)
      # 31: STA 200
      # 32: HLT

      machine.memory[0] = inst_class.new(address: 100, field: 5, opcode: inst_class::LDA).to_word
      machine.memory[1] = inst_class.new(address: 101, field: 5, opcode: inst_class::CMPA).to_word
      machine.memory[2] = inst_class.new(address: 10, field: 4, opcode: inst_class::JMP).to_word  # JL
      machine.memory[3] = inst_class.new(address: 20, field: 5, opcode: inst_class::JMP).to_word  # JE
      machine.memory[4] = inst_class.new(address: 30, field: 6, opcode: inst_class::JMP).to_word  # JG

      # Less path (address 10)
      machine.memory[10] = inst_class.new(address: 150, field: 5, opcode: inst_class::LDA).to_word
      machine.memory[11] = inst_class.new(address: 200, field: 5, opcode: inst_class::STA).to_word
      machine.memory[12] = inst_class.new(opcode: inst_class::HLT, field: 2).to_word

      # Equal path (address 20) - won't be used
      machine.memory[20] = inst_class.new(address: 151, field: 5, opcode: inst_class::LDA).to_word
      machine.memory[21] = inst_class.new(address: 200, field: 5, opcode: inst_class::STA).to_word
      machine.memory[22] = inst_class.new(opcode: inst_class::HLT, field: 2).to_word

      # Greater path (address 30) - won't be used
      machine.memory[30] = inst_class.new(address: 152, field: 5, opcode: inst_class::LDA).to_word
      machine.memory[31] = inst_class.new(address: 200, field: 5, opcode: inst_class::STA).to_word
      machine.memory[32] = inst_class.new(opcode: inst_class::HLT, field: 2).to_word

      # Values to load
      machine.memory[150] = word_class.from_i(1)  # "less" marker
      machine.memory[151] = word_class.from_i(2)  # "equal" marker
      machine.memory[152] = word_class.from_i(3)  # "greater" marker

      machine.run

      expect(machine.memory[200].to_i).to eq(1)  # Should have taken "less" path
      expect(machine.halted).to eq(true)
    end
  end
end
