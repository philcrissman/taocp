# frozen_string_literal: true

module Quackers
  module Mix
    # Manages MIX machine registers
    class Registers
      attr_accessor :a, :x, :i1, :i2, :i3, :i4, :i5, :i6, :j
      attr_accessor :comparison_flag, :overflow

      def initialize
        # A and X are full words
        @a = Word.new
        @x = Word.new

        # I1..I6 are 2-byte index registers (sign + 2 bytes)
        @i1 = Word.new(bytes: [0, 0, 0, 0, 0])
        @i2 = Word.new(bytes: [0, 0, 0, 0, 0])
        @i3 = Word.new(bytes: [0, 0, 0, 0, 0])
        @i4 = Word.new(bytes: [0, 0, 0, 0, 0])
        @i5 = Word.new(bytes: [0, 0, 0, 0, 0])
        @i6 = Word.new(bytes: [0, 0, 0, 0, 0])

        # J is jump address (always positive, 2 bytes)
        @j = 0

        # Comparison flag: :less, :equal, :greater
        @comparison_flag = :equal

        # Overflow toggle
        @overflow = false
      end

      def get_index(n)
        case n
        when 1 then @i1
        when 2 then @i2
        when 3 then @i3
        when 4 then @i4
        when 5 then @i5
        when 6 then @i6
        else raise Error, "Invalid index register: #{n}"
        end
      end
    end
  end
end
