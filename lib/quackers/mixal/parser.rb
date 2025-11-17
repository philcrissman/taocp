# frozen_string_literal: true

module Quackers
  module Mixal
    # Parser for MIXAL assembly
    class Parser
      # AST Node types
      Instruction = Struct.new(:label, :operation, :address, :index, :field, :line) do
        def initialize(label: nil, operation:, address: nil, index: nil, field: nil, line: 1)
          super(label, operation, address, index, field, line)
        end
      end

      PseudoOp = Struct.new(:label, :operation, :value, :line) do
        def initialize(label: nil, operation:, value: nil, line: 1)
          super(label, operation, value, line)
        end
      end

      # Parse tokens into AST
      def self.parse(tokens)
        new(tokens).parse
      end

      def initialize(tokens)
        @tokens = tokens
        @pos = 0
        @instructions = []
      end

      def parse
        # Group tokens by line
        lines = group_by_line(@tokens)

        # Parse each line
        lines.each do |line_num, line_tokens|
          next if line_tokens.empty?
          
          # Skip comment-only lines
          next if line_tokens.length == 1 && line_tokens[0].type == :comment

          instruction = parse_line(line_tokens, line_num)
          @instructions << instruction if instruction
        end

        @instructions
      end

      private

      def group_by_line(tokens)
        grouped = {}
        tokens.each do |token|
          next if token.type == :comment  # Skip comments for now
          grouped[token.line] ||= []
          grouped[token.line] << token
        end
        grouped
      end

      def parse_line(tokens, line_num)
        @line_tokens = tokens
        @token_pos = 0

        label = nil
        operation = nil
        address = nil
        index = nil
        field = nil

        # First token might be a label
        if current_token&.type == :label
          label = current_token.value
          advance
        end

        # Next must be operation
        if current_token&.type == :operation
          operation = current_token.value
          advance
        else
          raise Error, "Expected operation on line #{line_num}"
        end

        # Check if this is a pseudo-operation
        if pseudo_op?(operation)
          value = parse_pseudo_op_value
          return PseudoOp.new(label: label, operation: operation, value: value, line: line_num)
        end

        # Parse address field if present
        if current_token
          address = parse_address_expression
          
          # Check for index (comma)
          if current_token&.type == :comma
            advance  # skip comma
            
            # Check for index number or field spec
            if current_token&.type == :index
              index = current_token.value.to_i
              advance
            end
            
            # Check for field spec in parens
            if current_token&.type == :lparen
              field = parse_field_spec
            end
          elsif current_token&.type == :lparen
            # Field spec without index
            field = parse_field_spec
          end
        end

        Instruction.new(
          label: label,
          operation: operation,
          address: address,
          index: index,
          field: field,
          line: line_num
        )
      end

      def parse_address_expression
        # Parse simple address expression
        # Can be: number, symbol, literal, or expression (symbol+number, *+number, etc.)
        
        if current_token&.type == :literal
          value = current_token.value
          advance
          return value
        end

        # Build expression from tokens
        expr_tokens = []
        
        while current_token && [:number, :symbol, :current_address, :plus, :minus].include?(current_token.type)
          expr_tokens << current_token
          advance
          
          # Stop if we hit a comma or lparen (index/field spec)
          break if current_token&.type == :comma || current_token&.type == :lparen
        end

        # Convert expression tokens to a value/string
        if expr_tokens.empty?
          nil
        elsif expr_tokens.length == 1
          token = expr_tokens[0]
          case token.type
          when :number
            token.value
          when :symbol
            token.value
          when :current_address
            '*'
          end
        else
          # Build expression string
          expr_tokens.map { |t| 
            case t.type
            when :number then t.value.to_s
            when :symbol then t.value
            when :current_address then '*'
            when :plus then '+'
            when :minus then '-'
            end
          }.join('')
        end
      end

      def parse_field_spec
        # Parse (L:R) or (F)
        advance  # skip lparen
        
        left = nil
        right = nil
        
        if current_token&.type == :number
          left = current_token.value
          advance
        end
        
        if current_token&.type == :colon
          advance  # skip colon
          if current_token&.type == :number
            right = current_token.value
            advance
          end
        end
        
        # Skip rparen
        if current_token&.type == :rparen
          advance
        end
        
        # Return field spec
        if right
          "#{left}:#{right}"
        elsif left
          left.to_s
        else
          nil
        end
      end

      def parse_pseudo_op_value
        # Parse value for pseudo-ops (EQU, CON, ORIG, etc.)
        # This can be a number, symbol, or expression
        
        value_tokens = []
        
        while current_token && [:number, :symbol, :current_address, :plus, :minus].include?(current_token.type)
          value_tokens << current_token
          advance
        end
        
        if value_tokens.empty?
          nil
        elsif value_tokens.length == 1
          token = value_tokens[0]
          case token.type
          when :number then token.value
          when :symbol then token.value
          when :current_address then '*'
          end
        else
          # Build expression
          value_tokens.map { |t|
            case t.type
            when :number then t.value.to_s
            when :symbol then t.value
            when :current_address then '*'
            when :plus then '+'
            when :minus then '-'
            end
          }.join('')
        end
      end

      def pseudo_op?(operation)
        %w[ORIG EQU END CON ALF].include?(operation.upcase)
      end

      def current_token
        @line_tokens[@token_pos]
      end

      def advance
        @token_pos += 1
      end
    end
  end
end
