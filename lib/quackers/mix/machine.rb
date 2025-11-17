# frozen_string_literal: true

module Quackers
  module Mix
    # The MIX virtual machine
    class Machine
      attr_reader :memory, :registers
      attr_accessor :pc, :halted

      MAX_INSTRUCTIONS = 100_000  # Safety limit

      def initialize
        @memory = Memory.new
        @registers = Registers.new
        @pc = 0  # Program counter
        @halted = false
        @instruction_count = 0
      end

      # Run until HLT or error
      def run
        @instruction_count = 0
        until @halted
          step
          @instruction_count += 1
          if @instruction_count > MAX_INSTRUCTIONS
            raise Error, "Instruction limit exceeded (infinite loop?)"
          end
        end
        @instruction_count
      end

      # Execute one instruction
      def step
        return if @halted

        # Fetch
        word = @memory[@pc]
        instruction = Instruction.from_word(word)

        # Increment PC
        @pc += 1

        # Decode and execute
        execute(instruction)
      end

      def reset
        @memory = Memory.new
        @registers = Registers.new
        @pc = 0
        @halted = false
        @instruction_count = 0
      end

      def instruction_count
        @instruction_count
      end

      private

      # Execute an instruction
      def execute(inst)
        case inst.opcode
        when Instruction::NOP
          execute_nop(inst)
        when Instruction::HLT
          execute_hlt(inst)
        when Instruction::LDA
          execute_lda(inst)
        when Instruction::LDX
          execute_ldx(inst)
        when Instruction::LD1
          execute_ld1(inst)
        when Instruction::LD2
          execute_ld2(inst)
        when Instruction::LD3
          execute_ld3(inst)
        when Instruction::LD4
          execute_ld4(inst)
        when Instruction::LD5
          execute_ld5(inst)
        when Instruction::LD6
          execute_ld6(inst)
        when Instruction::STA
          execute_sta(inst)
        when Instruction::STX
          execute_stx(inst)
        when Instruction::ST1
          execute_st1(inst)
        when Instruction::ST2
          execute_st2(inst)
        when Instruction::ST3
          execute_st3(inst)
        when Instruction::ST4
          execute_st4(inst)
        when Instruction::ST5
          execute_st5(inst)
        when Instruction::ST6
          execute_st6(inst)
        when Instruction::STJ
          execute_stj(inst)
        when Instruction::STZ
          execute_stz(inst)
        when Instruction::ADD
          execute_add(inst)
        when Instruction::SUB
          execute_sub(inst)
        when Instruction::MUL
          execute_mul(inst)
        when Instruction::DIV
          execute_div(inst)
        else
          raise Error, "Unknown opcode: #{inst.opcode}"
        end
      end

      # Instruction implementations
      def execute_nop(inst)
        # No operation
      end

      def execute_hlt(inst)
        @halted = true
      end

      # Stub implementations for Step 8
      def execute_lda(inst); raise Error, "LDA not yet implemented"; end
      def execute_ldx(inst); raise Error, "LDX not yet implemented"; end
      def execute_ld1(inst); raise Error, "LD1 not yet implemented"; end
      def execute_ld2(inst); raise Error, "LD2 not yet implemented"; end
      def execute_ld3(inst); raise Error, "LD3 not yet implemented"; end
      def execute_ld4(inst); raise Error, "LD4 not yet implemented"; end
      def execute_ld5(inst); raise Error, "LD5 not yet implemented"; end
      def execute_ld6(inst); raise Error, "LD6 not yet implemented"; end
      def execute_sta(inst); raise Error, "STA not yet implemented"; end
      def execute_stx(inst); raise Error, "STX not yet implemented"; end
      def execute_st1(inst); raise Error, "ST1 not yet implemented"; end
      def execute_st2(inst); raise Error, "ST2 not yet implemented"; end
      def execute_st3(inst); raise Error, "ST3 not yet implemented"; end
      def execute_st4(inst); raise Error, "ST4 not yet implemented"; end
      def execute_st5(inst); raise Error, "ST5 not yet implemented"; end
      def execute_st6(inst); raise Error, "ST6 not yet implemented"; end
      def execute_stj(inst); raise Error, "STJ not yet implemented"; end
      def execute_stz(inst); raise Error, "STZ not yet implemented"; end
      def execute_add(inst); raise Error, "ADD not yet implemented"; end
      def execute_sub(inst); raise Error, "SUB not yet implemented"; end
      def execute_mul(inst); raise Error, "MUL not yet implemented"; end
      def execute_div(inst); raise Error, "DIV not yet implemented"; end
    end
  end
end
