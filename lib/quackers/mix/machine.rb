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
        when 5  # NUM, CHAR, HLT (distinguished by field)
          # TAOCP spec: NUM=field 0, CHAR=field 1, HLT=field 2
          case inst.field
          when 0
            execute_num(inst)
          when 1
            execute_char(inst)
          when 2
            execute_hlt(inst)
          else
            raise Error, "Unknown field #{inst.field} for opcode 5"
          end
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
        when Instruction::LDAN
          execute_ldan(inst)
        when Instruction::LDXN
          execute_ldxn(inst)
        when Instruction::LD1N
          execute_ld1n(inst)
        when Instruction::LD2N
          execute_ld2n(inst)
        when Instruction::LD3N
          execute_ld3n(inst)
        when Instruction::LD4N
          execute_ld4n(inst)
        when Instruction::LD5N
          execute_ld5n(inst)
        when Instruction::LD6N
          execute_ld6n(inst)
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
        when Instruction::CMPA
          execute_cmpa(inst)
        when Instruction::CMPX
          execute_cmpx(inst)
        when Instruction::CMP1
          execute_cmp1(inst)
        when Instruction::CMP2
          execute_cmp2(inst)
        when Instruction::CMP3
          execute_cmp3(inst)
        when Instruction::CMP4
          execute_cmp4(inst)
        when Instruction::CMP5
          execute_cmp5(inst)
        when Instruction::CMP6
          execute_cmp6(inst)
        when Instruction::JMP
          execute_jmp(inst)
        when Instruction::JAN
          execute_jan(inst)
        when Instruction::J1N
          execute_jin(inst, 1)
        when Instruction::J2N
          execute_jin(inst, 2)
        when Instruction::J3N
          execute_jin(inst, 3)
        when Instruction::J4N
          execute_jin(inst, 4)
        when Instruction::J5N
          execute_jin(inst, 5)
        when Instruction::J6N
          execute_jin(inst, 6)
        when Instruction::JXN
          execute_jxn(inst)
        when 48  # ENTA, ENNA, INCA, DECA (opcode for A register)
          execute_address_transfer_a(inst)
        when 49  # ENT1, ENN1, INC1, DEC1
          execute_address_transfer_i(inst, 1)
        when 50  # ENT2, ENN2, INC2, DEC2
          execute_address_transfer_i(inst, 2)
        when 51  # ENT3, ENN3, INC3, DEC3
          execute_address_transfer_i(inst, 3)
        when 52  # ENT4, ENN4, INC4, DEC4
          execute_address_transfer_i(inst, 4)
        when 53  # ENT5, ENN5, INC5, DEC5
          execute_address_transfer_i(inst, 5)
        when 54  # ENT6, ENN6, INC6, DEC6
          execute_address_transfer_i(inst, 6)
        when 55  # ENTX, ENNX, INCX, DECX (opcode for X register)
          execute_address_transfer_x(inst)
        when 6  # Shift instructions (SLA, SRA, SLAX, SRAX, SLC, SRC)
          execute_shift(inst)
        when 7  # MOVE instruction
          execute_move(inst)
        when Instruction::JBUS
          execute_jbus(inst)
        when Instruction::IOC
          execute_ioc(inst)
        when Instruction::IN
          execute_in(inst)
        when Instruction::OUT
          execute_out(inst)
        when Instruction::JRED
          execute_jred(inst)
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

      # NUM - Convert character representation in rA:rX to numeric value
      # Treats the 10 bytes as decimal digits (MIX char 30-39 = digits 0-9)
      def execute_num(inst)
        # Get all 10 bytes from A and X
        bytes = @registers.a.bytes + @registers.x.bytes
        sign = @registers.a.sign

        # Convert MIX character codes to digits
        # In MIX character set, 30-39 represent digits 0-9
        result = 0
        bytes.each do |byte|
          digit = byte - 30  # Convert MIX char code to digit value
          digit = 0 if digit < 0 || digit > 9  # Treat non-digits as 0
          result = result * 10 + digit
        end

        # Apply sign and store in rA
        result = sign * result
        @registers.a = Word.from_i(result)
      end

      # CHAR - Convert numeric value in rA to character representation
      # Stores 10 digit characters in rA:rX (using MIX chars 30-39)
      def execute_char(inst)
        value = @registers.a.to_i.abs  # Get absolute value
        sign = @registers.a.sign

        # Convert to 10 decimal digits
        digits = []
        10.times do
          digits.unshift(value % 10)
          value /= 10
        end

        # Convert digits to MIX character codes (30-39 for 0-9)
        char_bytes = digits.map { |d| d + 30 }

        # Store in A and X (5 bytes each)
        @registers.a = Word.new(sign: sign, bytes: char_bytes[0..4])
        @registers.x = Word.new(sign: sign, bytes: char_bytes[5..9])
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

      # Load negative instructions
      def execute_ldan(inst)
        load_register_negative(inst, :a)
      end

      def execute_ldxn(inst)
        load_register_negative(inst, :x)
      end

      def execute_ld1n(inst)
        load_index_register_negative(inst, 1)
      end

      def execute_ld2n(inst)
        load_index_register_negative(inst, 2)
      end

      def execute_ld3n(inst)
        load_index_register_negative(inst, 3)
      end

      def execute_ld4n(inst)
        load_index_register_negative(inst, 4)
      end

      def execute_ld5n(inst)
        load_index_register_negative(inst, 5)
      end

      def execute_ld6n(inst)
        load_index_register_negative(inst, 6)
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

      # Helper: Load negative from memory into a register
      def load_register_negative(inst, register_name)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)

        # Default field is (0:5) - whole word
        l, r = 0, 5 if inst.field == 0

        # Load field from memory and negate
        value = @memory[m].slice(l, r)
        negated = Word.new(sign: -value.sign, bytes: value.bytes.dup)

        # Store into register
        case register_name
        when :a
          @registers.a = negated
        when :x
          @registers.x = negated
        end
      end

      # Helper: Load negative into index register
      def load_index_register_negative(inst, index_num)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)

        # Default field for index registers is also (0:5)
        l, r = 0, 5 if inst.field == 0

        # Load field from memory and negate
        value = @memory[m].slice(l, r)
        negated = Word.new(sign: -value.sign, bytes: value.bytes.dup)

        # Store into index register
        @registers.set_index(index_num, negated)
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

      # Comparison instructions
      def execute_cmpa(inst)
        compare_register(inst, @registers.a)
      end

      def execute_cmpx(inst)
        compare_register(inst, @registers.x)
      end

      def execute_cmp1(inst)
        compare_register(inst, @registers.get_index(1))
      end

      def execute_cmp2(inst)
        compare_register(inst, @registers.get_index(2))
      end

      def execute_cmp3(inst)
        compare_register(inst, @registers.get_index(3))
      end

      def execute_cmp4(inst)
        compare_register(inst, @registers.get_index(4))
      end

      def execute_cmp5(inst)
        compare_register(inst, @registers.get_index(5))
      end

      def execute_cmp6(inst)
        compare_register(inst, @registers.get_index(6))
      end

      # Helper: Compare register with memory value
      def compare_register(inst, register_value)
        m = inst.effective_address(@registers)
        l, r = Word.decode_field_spec(inst.field)
        l, r = 0, 5 if inst.field == 0

        # Get value from memory
        memory_value = @memory[m].slice(l, r)

        # Compare register with memory
        reg_int = register_value.to_i
        mem_int = memory_value.to_i

        if reg_int < mem_int
          @registers.comparison_flag = :less
        elsif reg_int == mem_int
          @registers.comparison_flag = :equal
        else
          @registers.comparison_flag = :greater
        end
      end

      # Jump instructions
      # JMP uses field spec to determine condition
      def execute_jmp(inst)
        m = inst.effective_address(@registers)

        # Field determines jump condition
        case inst.field
        when 0  # JMP - unconditional jump
          @registers.j = @pc  # Save return address
          @pc = m
        when 1  # JSJ - jump, save J (but don't modify J)
          @pc = m
        when 2  # JOV - jump on overflow
          if @registers.overflow
            @registers.j = @pc
            @pc = m
            @registers.overflow = false  # Reset overflow
          end
        when 3  # JNOV - jump on no overflow
          unless @registers.overflow
            @registers.j = @pc
            @pc = m
          else
            @registers.overflow = false
          end
        when 4  # JL - jump if less
          if @registers.comparison_flag == :less
            @registers.j = @pc
            @pc = m
          end
        when 5  # JE - jump if equal
          if @registers.comparison_flag == :equal
            @registers.j = @pc
            @pc = m
          end
        when 6  # JG - jump if greater
          if @registers.comparison_flag == :greater
            @registers.j = @pc
            @pc = m
          end
        when 7  # JGE - jump if greater or equal
          if @registers.comparison_flag == :greater || @registers.comparison_flag == :equal
            @registers.j = @pc
            @pc = m
          end
        when 8  # JNE - jump if not equal
          if @registers.comparison_flag != :equal
            @registers.j = @pc
            @pc = m
          end
        when 9  # JLE - jump if less or equal
          if @registers.comparison_flag == :less || @registers.comparison_flag == :equal
            @registers.j = @pc
            @pc = m
          end
        end
      end

      # JAN - jump on A negative/zero/positive/etc.
      def execute_jan(inst)
        m = inst.effective_address(@registers)
        a_value = @registers.a.to_i

        # Field determines condition
        case inst.field
        when 0  # JAN - jump if A negative
          if a_value < 0
            @registers.j = @pc
            @pc = m
          end
        when 1  # JAZ - jump if A zero
          if a_value == 0
            @registers.j = @pc
            @pc = m
          end
        when 2  # JAP - jump if A positive
          if a_value > 0
            @registers.j = @pc
            @pc = m
          end
        when 3  # JANN - jump if A non-negative
          if a_value >= 0
            @registers.j = @pc
            @pc = m
          end
        when 4  # JANZ - jump if A non-zero
          if a_value != 0
            @registers.j = @pc
            @pc = m
          end
        when 5  # JANP - jump if A non-positive
          if a_value <= 0
            @registers.j = @pc
            @pc = m
          end
        end
      end

      # JiN - jump on index register i negative/zero/positive/etc.
      def execute_jin(inst, reg_num)
        m = inst.effective_address(@registers)
        reg_value = @registers.get_index_i(reg_num)

        # Field determines condition
        case inst.field
        when 0  # JiN - jump if Ii negative
          if reg_value < 0
            @registers.j = @pc
            @pc = m
          end
        when 1  # JiZ - jump if Ii zero
          if reg_value == 0
            @registers.j = @pc
            @pc = m
          end
        when 2  # JiP - jump if Ii positive
          if reg_value > 0
            @registers.j = @pc
            @pc = m
          end
        when 3  # JiNN - jump if Ii non-negative
          if reg_value >= 0
            @registers.j = @pc
            @pc = m
          end
        when 4  # JiNZ - jump if Ii non-zero
          if reg_value != 0
            @registers.j = @pc
            @pc = m
          end
        when 5  # JiNP - jump if Ii non-positive
          if reg_value <= 0
            @registers.j = @pc
            @pc = m
          end
        end
      end

      # JXN - jump on X negative/zero/positive/etc.
      def execute_jxn(inst)
        m = inst.effective_address(@registers)
        x_value = @registers.x.to_i

        # Field determines condition
        case inst.field
        when 0  # JXN - jump if X negative
          if x_value < 0
            @registers.j = @pc
            @pc = m
          end
        when 1  # JXZ - jump if X zero
          if x_value == 0
            @registers.j = @pc
            @pc = m
          end
        when 2  # JXP - jump if X positive
          if x_value > 0
            @registers.j = @pc
            @pc = m
          end
        when 3  # JXNN - jump if X non-negative
          if x_value >= 0
            @registers.j = @pc
            @pc = m
          end
        when 4  # JXNZ - jump if X non-zero
          if x_value != 0
            @registers.j = @pc
            @pc = m
          end
        when 5  # JXNP - jump if X non-positive
          if x_value <= 0
            @registers.j = @pc
            @pc = m
          end
        end
      end

      # Address transfer operations for A register
      # Field: 0=ENTA, 1=ENNA, 2=INCA, 3=DECA
      def execute_address_transfer_a(inst)
        m = inst.effective_address(@registers)

        case inst.field
        when 0  # ENTA - Enter A
          @registers.a = Word.from_i(m)
        when 1  # ENNA - Enter negative A
          @registers.a = Word.from_i(-m)
        when 2  # INCA - Increase A
          new_value = @registers.a.to_i + m
          # Check overflow
          if new_value.abs > Word::MAX_VALUE
            @registers.overflow = true
            sign = new_value < 0 ? -1 : 1
            new_value = sign * (new_value.abs % (Word::MAX_VALUE + 1))
          end
          @registers.a = Word.from_i(new_value)
        when 3  # DECA - Decrease A
          new_value = @registers.a.to_i - m
          # Check overflow
          if new_value.abs > Word::MAX_VALUE
            @registers.overflow = true
            sign = new_value < 0 ? -1 : 1
            new_value = sign * (new_value.abs % (Word::MAX_VALUE + 1))
          end
          @registers.a = Word.from_i(new_value)
        end
      end

      # Address transfer operations for X register
      # Field: 0=ENTX, 1=ENNX, 2=INCX, 3=DECX
      def execute_address_transfer_x(inst)
        m = inst.effective_address(@registers)

        case inst.field
        when 0  # ENTX - Enter X
          @registers.x = Word.from_i(m)
        when 1  # ENNX - Enter negative X
          @registers.x = Word.from_i(-m)
        when 2  # INCX - Increase X
          new_value = @registers.x.to_i + m
          if new_value.abs > Word::MAX_VALUE
            @registers.overflow = true
            sign = new_value < 0 ? -1 : 1
            new_value = sign * (new_value.abs % (Word::MAX_VALUE + 1))
          end
          @registers.x = Word.from_i(new_value)
        when 3  # DECX - Decrease X
          new_value = @registers.x.to_i - m
          if new_value.abs > Word::MAX_VALUE
            @registers.overflow = true
            sign = new_value < 0 ? -1 : 1
            new_value = sign * (new_value.abs % (Word::MAX_VALUE + 1))
          end
          @registers.x = Word.from_i(new_value)
        end
      end

      # Address transfer operations for index registers
      # Field: 0=ENTi, 1=ENNi, 2=INCi, 3=DECi
      def execute_address_transfer_i(inst, index_num)
        m = inst.effective_address(@registers)

        case inst.field
        when 0  # ENTi - Enter index
          @registers.set_index_i(index_num, m)
        when 1  # ENNi - Enter negative index
          @registers.set_index_i(index_num, -m)
        when 2  # INCi - Increase index
          current = @registers.get_index_i(index_num)
          new_value = current + m
          # Index registers have 2-byte capacity (max 4095)
          if new_value.abs > 4095
            @registers.overflow = true
            sign = new_value < 0 ? -1 : 1
            new_value = sign * (new_value.abs % 4096)
          end
          @registers.set_index_i(index_num, new_value)
        when 3  # DECi - Decrease index
          current = @registers.get_index_i(index_num)
          new_value = current - m
          if new_value.abs > 4095
            @registers.overflow = true
            sign = new_value < 0 ? -1 : 1
            new_value = sign * (new_value.abs % 4096)
          end
          @registers.set_index_i(index_num, new_value)
        end
      end

      # Shift operations
      # Field: 0=SLA, 1=SRA, 2=SLAX, 3=SRAX, 4=SLC, 5=SRC
      # M (address) = number of positions to shift
      def execute_shift(inst)
        m = inst.effective_address(@registers)

        case inst.field
        when 0  # SLA - Shift left A
          shift_left_a(m)
        when 1  # SRA - Shift right A
          shift_right_a(m)
        when 2  # SLAX - Shift left AX
          shift_left_ax(m)
        when 3  # SRAX - Shift right AX
          shift_right_ax(m)
        when 4  # SLC - Shift left circular
          shift_left_circular(m)
        when 5  # SRC - Shift right circular
          shift_right_circular(m)
        end
      end

      # Shift A left by m positions, filling with zeros
      def shift_left_a(m)
        bytes = @registers.a.bytes.dup
        sign = @registers.a.sign

        m = m % 5  # Only 5 bytes to shift
        if m > 0
          # Shift left: move bytes left, fill right with zeros
          bytes = bytes[m..-1] + [0] * m
        end

        @registers.a = Word.new(sign: sign, bytes: bytes)
      end

      # Shift A right by m positions, filling with zeros
      def shift_right_a(m)
        bytes = @registers.a.bytes.dup
        sign = @registers.a.sign

        m = m % 5
        if m > 0
          # Shift right: move bytes right, fill left with zeros
          bytes = [0] * m + bytes[0...(5 - m)]
        end

        @registers.a = Word.new(sign: sign, bytes: bytes)
      end

      # Shift A:X left by m positions (10 bytes total)
      def shift_left_ax(m)
        # Combine A and X bytes (A is high, X is low)
        sign_a = @registers.a.sign
        sign_x = @registers.x.sign
        all_bytes = @registers.a.bytes + @registers.x.bytes

        m = m % 10
        if m > 0
          all_bytes = all_bytes[m..-1] + [0] * m
        end

        @registers.a = Word.new(sign: sign_a, bytes: all_bytes[0..4])
        @registers.x = Word.new(sign: sign_x, bytes: all_bytes[5..9])
      end

      # Shift A:X right by m positions (10 bytes total)
      def shift_right_ax(m)
        sign_a = @registers.a.sign
        sign_x = @registers.x.sign
        all_bytes = @registers.a.bytes + @registers.x.bytes

        m = m % 10
        if m > 0
          all_bytes = [0] * m + all_bytes[0...(10 - m)]
        end

        @registers.a = Word.new(sign: sign_a, bytes: all_bytes[0..4])
        @registers.x = Word.new(sign: sign_x, bytes: all_bytes[5..9])
      end

      # Circular shift A:X left by m positions
      def shift_left_circular(m)
        sign_a = @registers.a.sign
        sign_x = @registers.x.sign
        all_bytes = @registers.a.bytes + @registers.x.bytes

        m = m % 10
        if m > 0
          # Rotate left: take first m bytes and move to end
          all_bytes = all_bytes[m..-1] + all_bytes[0...m]
        end

        @registers.a = Word.new(sign: sign_a, bytes: all_bytes[0..4])
        @registers.x = Word.new(sign: sign_x, bytes: all_bytes[5..9])
      end

      # Circular shift A:X right by m positions
      def shift_right_circular(m)
        sign_a = @registers.a.sign
        sign_x = @registers.x.sign
        all_bytes = @registers.a.bytes + @registers.x.bytes

        m = m % 10
        if m > 0
          # Rotate right: take last m bytes and move to beginning
          all_bytes = all_bytes[-m..-1] + all_bytes[0...(10 - m)]
        end

        @registers.a = Word.new(sign: sign_a, bytes: all_bytes[0..4])
        @registers.x = Word.new(sign: sign_x, bytes: all_bytes[5..9])
      end

      # MOVE instruction: Move F words from M to location stored in I1
      # After execution, I1 is increased by F
      def execute_move(inst)
        m = inst.effective_address(@registers)
        f = inst.field  # Number of words to move
        destination = @registers.get_index_i(1)

        # Move F words from address M to address destination
        f.times do |i|
          @memory[destination + i] = @memory[m + i]
        end

        # Update I1
        @registers.set_index_i(1, destination + f)
      end

      # I/O instruction stubs (not fully implemented)
      # These are placeholders for future I/O device implementation

      # IN - Input from device F to memory at M
      def execute_in(inst)
        # Stub: No-op for now
        # Future: Transfer data from device F to memory starting at M
      end

      # OUT - Output to device F from memory at M
      def execute_out(inst)
        # Stub: No-op for now
        # Future: Transfer data to device F from memory starting at M
      end

      # IOC - I/O control for device F
      def execute_ioc(inst)
        # Stub: No-op for now
        # Future: Send control signal to device F
      end

      # JBUS - Jump if device F is busy
      def execute_jbus(inst)
        # Stub: Never jump (assume all devices are ready)
        # Future: Check if device F is busy, jump to M if so
      end

      # JRED - Jump if device F is ready
      def execute_jred(inst)
        # Stub: Always jump (assume all devices are ready)
        # Future: Check if device F is ready, jump to M if so
        m = inst.effective_address(@registers)
        @pc = m
      end
    end
  end
end
