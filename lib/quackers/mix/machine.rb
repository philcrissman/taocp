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

      # Load instructions
      def execute_lda(inst)
        load_register(inst, :a)
      end

      def execute_ldx(inst)
        load_register(inst, :x)
      end

      def execute_ld1(inst)
        load_index_register(inst, 1)
      end

      def execute_ld2(inst)
        load_index_register(inst, 2)
      end

      def execute_ld3(inst)
        load_index_register(inst, 3)
      end

      def execute_ld4(inst)
        load_index_register(inst, 4)
      end

      def execute_ld5(inst)
        load_index_register(inst, 5)
      end

      def execute_ld6(inst)
        load_index_register(inst, 6)
      end

      # Helper: Load from memory into a register
      def load_register(inst, register_name)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)

        # Default field is (0:5) - whole word
        l, r = 0, 5 if inst.field == 0

        # Load field from memory
        value = @memory[m].slice(l, r)

        # Store into register
        case register_name
        when :a
          @registers.a = value
        when :x
          @registers.x = value
        end
      end

      # Helper: Load into index register (2-byte registers)
      def load_index_register(inst, index_num)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)

        # Default field for index registers is also (0:5)
        l, r = 0, 5 if inst.field == 0

        # Load field from memory
        value = @memory[m].slice(l, r)

        # Store into index register
        @registers.set_index(index_num, value)
      end
      # Store instructions
      def execute_sta(inst)
        store_register(inst, @registers.a)
      end

      def execute_stx(inst)
        store_register(inst, @registers.x)
      end

      def execute_st1(inst)
        store_register(inst, @registers.get_index(1))
      end

      def execute_st2(inst)
        store_register(inst, @registers.get_index(2))
      end

      def execute_st3(inst)
        store_register(inst, @registers.get_index(3))
      end

      def execute_st4(inst)
        store_register(inst, @registers.get_index(4))
      end

      def execute_st5(inst)
        store_register(inst, @registers.get_index(5))
      end

      def execute_st6(inst)
        store_register(inst, @registers.get_index(6))
      end

      def execute_stj(inst)
        # STJ stores the J register (always positive, 2 bytes)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)
        l, r = 0, 5 if inst.field == 0

        # J is stored as an integer, convert to word
        j_word = Word.from_i(@registers.j)

        @memory[m].store_slice!(l, r, j_word)
      end

      def execute_stz(inst)
        # STZ stores zero
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)
        l, r = 0, 5 if inst.field == 0

        zero_word = Word.new(sign: 1, bytes: [0, 0, 0, 0, 0])
        @memory[m].store_slice!(l, r, zero_word)
      end

      # Helper: Store register value to memory
      def store_register(inst, register_value)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)

        # Default field is (0:5)
        l, r = 0, 5 if inst.field == 0

        # Store field into memory
        @memory[m].store_slice!(l, r, register_value)
      end
      # Arithmetic instructions
      def execute_add(inst)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)
        l, r = 0, 5 if inst.field == 0

        # Get value from memory
        value = @memory[m].slice(l, r)

        # Add to register A
        result = @registers.a.to_i + value.to_i

        # Check for overflow
        if result.abs > Word::MAX_VALUE
          @registers.overflow = true
          # Wrap around (modulo arithmetic)
          sign = result < 0 ? -1 : 1
          result = sign * (result.abs % (Word::MAX_VALUE + 1))
        end

        @registers.a = Word.from_i(result)
      end

      def execute_sub(inst)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)
        l, r = 0, 5 if inst.field == 0

        # Get value from memory
        value = @memory[m].slice(l, r)

        # Subtract from register A
        result = @registers.a.to_i - value.to_i

        # Check for overflow
        if result.abs > Word::MAX_VALUE
          @registers.overflow = true
          # Wrap around
          sign = result < 0 ? -1 : 1
          result = sign * (result.abs % (Word::MAX_VALUE + 1))
        end

        @registers.a = Word.from_i(result)
      end

      def execute_mul(inst)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)
        l, r = 0, 5 if inst.field == 0

        # Get value from memory
        value = @memory[m].slice(l, r)

        # Multiply rA by V
        result = @registers.a.to_i * value.to_i

        # MUL produces a 10-byte result split across rA (high) and rX (low)
        # Result sign is product of signs
        sign = result < 0 ? -1 : 1
        abs_result = result.abs

        # Split into high and low parts
        # High part: result / (MAX_VALUE + 1)
        # Low part: result % (MAX_VALUE + 1)
        high = abs_result / (Word::MAX_VALUE + 1)
        low = abs_result % (Word::MAX_VALUE + 1)

        @registers.a = Word.from_i(sign * high)
        @registers.x = Word.from_i(sign * low)
      end

      def execute_div(inst)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)
        l, r = 0, 5 if inst.field == 0

        # Get divisor from memory
        divisor_word = @memory[m].slice(l, r)
        divisor = divisor_word.to_i

        # Check for division by zero
        if divisor == 0
          @registers.overflow = true
          return
        end

        # Dividend is rA:rX (10 bytes total)
        # Construct dividend from rA (high) and rX (low)
        a_value = @registers.a.to_i
        x_value = @registers.x.to_i.abs  # X magnitude only

        sign = a_value < 0 ? -1 : 1
        dividend = sign * (a_value.abs * (Word::MAX_VALUE + 1) + x_value)

        # Perform division
        quotient = dividend / divisor
        remainder = dividend % divisor

        # Check for overflow (quotient too large)
        if quotient.abs > Word::MAX_VALUE
          @registers.overflow = true
          return
        end

        # Store results
        @registers.a = Word.from_i(quotient)
        @registers.x = Word.from_i(remainder)
      end
    end
  end
end
