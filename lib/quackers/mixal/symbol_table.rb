# frozen_string_literal: true

module Quackers
  module Mixal
    # Symbol table for MIXAL assembly
    class SymbolTable
      class Error < Mixal::Error; end

      def initialize
        @symbols = {}
        @forward_refs = {}  # Track forward references
      end

      # Define a symbol with a value
      def define(name, value)
        name = name.to_s.upcase
        
        if @symbols.key?(name)
          raise Error, "Symbol '#{name}' already defined"
        end
        
        @symbols[name] = value
      end

      # Look up a symbol's value
      def lookup(name)
        name = name.to_s.upcase
        @symbols[name]
      end

      # Check if symbol is defined
      def defined?(name)
        name = name.to_s.upcase
        @symbols.key?(name)
      end

      # Get all symbols
      def all
        @symbols.dup
      end

      # Evaluate an expression that may contain symbols
      # Returns numeric value or raises error if undefined symbol
      def evaluate(expr)
        return expr if expr.is_a?(Integer)
        
        expr_str = expr.to_s
        
        # Handle special case: current address (*)
        # This should be handled by caller passing the current location
        return expr if expr_str == '*'
        
        # Try to parse as integer
        if expr_str =~ /^-?\d+$/
          return expr_str.to_i
        end
        
        # Handle simple symbol
        if expr_str =~ /^[A-Z][A-Z0-9]*$/
          value = lookup(expr_str)
          if value.nil?
            raise Error, "Undefined symbol: #{expr_str}"
          end
          return value
        end
        
        # Handle expression (SYMBOL+NUM, SYMBOL-NUM, etc.)
        if expr_str =~ /^([A-Z][A-Z0-9]*)([\+\-])(\d+)$/
          symbol = $1
          op = $2
          num = $3.to_i
          
          base = lookup(symbol)
          if base.nil?
            raise Error, "Undefined symbol: #{symbol}"
          end
          
          return op == '+' ? base + num : base - num
        end
        
        # Handle *+NUM or *-NUM (current address relative)
        if expr_str =~ /^\*([\+\-])(\d+)$/
          # Return as-is, will be resolved by caller with current location
          return expr
        end
        
        # Unknown expression format
        raise Error, "Cannot evaluate expression: #{expr}"
      end

      # Evaluate expression with current location for * operator
      def evaluate_with_location(expr, location)
        return expr if expr.is_a?(Integer)
        
        expr_str = expr.to_s
        
        # Handle * (current address)
        if expr_str == '*'
          return location
        end
        
        # Handle *+NUM or *-NUM
        if expr_str =~ /^\*([\+\-])(\d+)$/
          op = $1
          num = $2.to_i
          return op == '+' ? location + num : location - num
        end
        
        # Otherwise use regular evaluation
        evaluate(expr)
      end
    end
  end
end
