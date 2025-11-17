# frozen_string_literal: true

module Quackers
  module Mix
    # Manages MIX machine memory (4000 words)
    class Memory
      MEMORY_SIZE = 4000

      def initialize
        @cells = Array.new(MEMORY_SIZE) { Word.new }
      end

      def [](address)
        validate_address!(address)
        @cells[address]
      end

      def []=(address, word)
        validate_address!(address)
        @cells[address] = word
      end

      private

      def validate_address!(address)
        unless address >= 0 && address < MEMORY_SIZE
          raise Error, "Invalid memory address: #{address} (must be 0..#{MEMORY_SIZE - 1})"
        end
      end
    end
  end
end
