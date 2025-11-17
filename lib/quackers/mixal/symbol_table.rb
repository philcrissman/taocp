# frozen_string_literal: true

module Quackers
  module Mixal
    # Tracks labels and their addresses during assembly
    class SymbolTable
      def initialize
        @symbols = {}
      end

      def define(label, value)
        @symbols[label] = value
      end

      def lookup(label)
        @symbols[label]
      end

      def defined?(label)
        @symbols.key?(label)
      end
    end
  end
end
