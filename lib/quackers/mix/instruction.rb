# frozen_string_literal: true

module Quackers
  module Mix
    # Represents a MIX instruction
    # Format: ± AA II F C
    #   ± = sign (byte 0)
    #   AA = address (bytes 1-2, 0..4095)
    #   II = index (byte 3, 0..6)
    #   F  = field specification (byte 4, 0..63)
    #   C  = operation code (byte 5, 0..63)
    class Instruction
      attr_reader :address, :index, :field, :opcode, :sign

      # Opcode constants (TAOCP Section 1.3.1)
      # Load instructions
      LDA  = 8   # Load A
      LDX  = 15  # Load X
      LD1  = 9   # Load I1
      LD2  = 10  # Load I2
      LD3  = 11  # Load I3
      LD4  = 12  # Load I4
      LD5  = 13  # Load I5
      LD6  = 14  # Load I6
      LDAN = 16  # Load A negative
      LDXN = 23  # Load X negative
      LD1N = 17  # Load I1 negative
      LD2N = 18  # Load I2 negative
      LD3N = 19  # Load I3 negative
      LD4N = 20  # Load I4 negative
      LD5N = 21  # Load I5 negative
      LD6N = 22  # Load I6 negative

      # Store instructions
      STA  = 24  # Store A
      STX  = 31  # Store X
      ST1  = 25  # Store I1
      ST2  = 26  # Store I2
      ST3  = 27  # Store I3
      ST4  = 28  # Store I4
      ST5  = 29  # Store I5
      ST6  = 30  # Store I6
      STJ  = 32  # Store J
      STZ  = 33  # Store zero

      # Arithmetic
      ADD  = 1   # Add
      SUB  = 2   # Subtract
      MUL  = 3   # Multiply
      DIV  = 4   # Divide

      # Address transfer
      INCA = 48  # Increase A
      INCX = 55  # Increase X
      INC1 = 49  # Increase I1
      INC2 = 50  # Increase I2
      INC3 = 51  # Increase I3
      INC4 = 52  # Increase I4
      INC5 = 53  # Increase I5
      INC6 = 54  # Increase I6
      DECA = 48  # Decrease A
      DECX = 55  # Decrease X
      DEC1 = 49  # Decrease I1
      DEC2 = 50  # Decrease I2
      DEC3 = 51  # Decrease I3
      DEC4 = 52  # Decrease I4
      DEC5 = 53  # Decrease I5
      DEC6 = 54  # Decrease I6
      ENTA = 48  # Enter A
      ENTX = 55  # Enter X
      ENT1 = 49  # Enter I1
      ENT2 = 50  # Enter I2
      ENT3 = 51  # Enter I3
      ENT4 = 52  # Enter I4
      ENT5 = 53  # Enter I5
      ENT6 = 54  # Enter I6
      ENNX = 55  # Enter negative X
      ENN1 = 49  # Enter negative I1

      # Comparison
      CMPA = 56  # Compare A
      CMPX = 63  # Compare X
      CMP1 = 57  # Compare I1
      CMP2 = 58  # Compare I2
      CMP3 = 59  # Compare I3
      CMP4 = 60  # Compare I4
      CMP5 = 61  # Compare I5
      CMP6 = 62  # Compare I6

      # Jump instructions
      JMP  = 39  # Jump
      JSJ  = 39  # Jump, save J
      JOV  = 39  # Jump on overflow
      JNOV = 39  # Jump no overflow
      JL   = 39  # Jump less
      JE   = 39  # Jump equal
      JG   = 39  # Jump greater
      JGE  = 39  # Jump greater or equal
      JNE  = 39  # Jump not equal
      JLE  = 39  # Jump less or equal
      JAN  = 40  # Jump A negative
      JAZ  = 40  # Jump A zero
      JAP  = 40  # Jump A positive
      JANN = 40  # Jump A non-negative
      JANZ = 40  # Jump A non-zero
      JANP = 40  # Jump A non-positive

      # Miscellaneous
      NOP  = 0   # No operation
      HLT  = 5   # Halt
      MOVE = 7   # Move
      NUM  = 5   # Convert to numeric
      CHAR = 5   # Convert to characters
      SLA  = 6   # Shift left A
      SRA  = 6   # Shift right A
      SLAX = 6   # Shift left AX
      SRAX = 6   # Shift right AX
      SLC  = 6   # Shift left circular
      SRC  = 6   # Shift right circular

      def initialize(address: 0, index: 0, field: 0, opcode: 0, sign: 1)
        @address = address
        @index = index
        @field = field
        @opcode = opcode
        @sign = sign
      end

      # Decode an instruction from a MIX word
      def self.from_word(word)
        sign = word.sign
        # Address is bytes 1-2 (each 0..63), giving range 0..4095
        address = word.bytes[0] * 64 + word.bytes[1]
        index = word.bytes[2]
        field = word.bytes[3]
        opcode = word.bytes[4]

        new(address: address, index: index, field: field, opcode: opcode, sign: sign)
      end

      # Encode this instruction as a MIX word
      def to_word
        # Split address into two bytes
        addr_high = @address / 64
        addr_low = @address % 64

        Word.new(
          sign: @sign,
          bytes: [addr_high, addr_low, @index, @field, @opcode]
        )
      end

      # Calculate the effective address (M) for this instruction
      # M = address ± contents of index register (if index != 0)
      def effective_address(registers)
        m = @sign * @address
        if @index > 0
          # Add index register value (using only bytes 4:5, the rightmost 2 bytes)
          index_value = registers.get_index(@index).slice(4, 5).to_i
          m += index_value
        end
        m.abs  # MIX addresses are always positive
      end

      def inspect
        sign_str = @sign >= 0 ? "+" : "-"
        "#<Mix::Instruction #{sign_str}#{@address},#{@index}(#{@field}) C=#{@opcode}>"
      end

      def to_s
        sign_str = @sign >= 0 ? "+" : "-"
        "#{sign_str}#{@address.to_s.rjust(4, '0')} #{@index} #{@field} #{@opcode}"
      end
    end
  end
end
