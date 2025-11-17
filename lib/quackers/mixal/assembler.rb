# frozen_string_literal: true

module Quackers
  module Mixal
    # Two-pass MIXAL assembler
    class Assembler
      def initialize(source)
        @source = source
        @symbol_table = SymbolTable.new
      end

      def assemble
        # TODO: Implement in Steps 14-17
        raise Error, "Assembler not yet implemented"
      end

      private

      def pass1
        # TODO: Collect labels, EQU, ORIG, literals
      end

      def pass2
        # TODO: Emit machine words, resolve addresses
      end
    end
  end
end
