# frozen_string_literal: true

module Taocp
  module Mixal
    # Tokenizes MIXAL assembly source code
    class Lexer
      # Token types
      Token = Struct.new(:type, :value, :line, :column) do
        def inspect
          "<#{type}: #{value.inspect}>"
        end
      end

      # Tokenize MIXAL source code
      # Returns array of tokens
      def self.tokenize(source)
        new(source).tokenize
      end

      def initialize(source)
        @source = source
        @lines = source.split("\n")
        @tokens = []
      end

      def tokenize
        @lines.each_with_index do |line, line_num|
          tokenize_line(line, line_num + 1)
        end
        @tokens
      end

      private

      def tokenize_line(line, line_num)
        # Handle empty lines
        return if line.strip.empty?

        # Full-line comment (starts with *)
        if line =~ /^\*/
          @tokens << Token.new(:comment, line.strip, line_num, 1)
          return
        end

        # Parse MIXAL line format: [LABEL] OPERATION [ADDRESS][,INDEX][(FIELD)] [COMMENT]
        # MIXAL traditionally uses column-based format, but we'll be more flexible

        # Split by whitespace to get fields
        parts = line.split(/\s+/, 3)  # Split into at most 3 parts

        col = 1
        label = nil
        operation = nil

        # Determine if first token is a label or operation
        if parts.length > 0
          first = parts[0]

          # Check if it's an operation (all CAPS or known pseudo-op)
          if is_operation?(first)
            operation = first
            parts.shift
          else
            # It's a label
            label = first
            parts.shift
            @tokens << Token.new(:label, label, line_num, col)
            col += label.length + 1
          end
        end

        # Next part is operation (if we haven't found it yet)
        if parts.length > 0 && operation.nil?
          operation = parts.shift
          @tokens << Token.new(:operation, operation, line_num, col)
          col += operation.length + 1
        elsif operation
          @tokens << Token.new(:operation, operation, line_num, col)
          col += operation.length + 1
        end

        # Rest is address field (including index, field spec) and optional comment
        if parts.length > 0
          rest = parts.join(" ")
          tokenize_address_and_comment(rest, line_num, col)
        end
      end

      def tokenize_address_and_comment(text, line_num, start_col)
        # Check if there's a comment (not inside quotes)
        comment_pos = find_comment_start(text)

        if comment_pos
          address_text = text[0...comment_pos].strip
          comment_text = text[comment_pos..-1].strip

          tokenize_address_field(address_text, line_num, start_col) unless address_text.empty?
          @tokens << Token.new(:comment, comment_text, line_num, start_col + comment_pos)
        else
          tokenize_address_field(text.strip, line_num, start_col) unless text.strip.empty?
        end
      end

      def tokenize_address_field(text, line_num, col)
        # Parse address field: EXPRESSION[,INDEX][(FIELD)]
        # Example: 1000,1(2:5)
        # Example: LABEL+10
        # Example: =5= (literal)
        # Example: 1000(1:5) - address with field spec, no index

        # Check for literal (=...=)
        if text =~ /^(=.+=)/
          @tokens << Token.new(:literal, $1, line_num, col)
          text = $'
          col += $1.length
        end

        # Check if there's a field spec directly attached to address (no comma)
        # Pattern: ADDRESS(FIELD) where ADDRESS has no comma
        if !text.include?(',') && text =~ /^([^(]+)\((.+)\)$/
          # Address with field spec, no index: "1000(1:5)"
          address_expr = $1
          field_spec = $2

          tokenize_expression(address_expr, line_num, col)
          col += address_expr.length

          @tokens << Token.new(:lparen, '(', line_num, col)
          col += 1
          tokenize_field_spec(field_spec, line_num, col)
          col += field_spec.length
          @tokens << Token.new(:rparen, ')', line_num, col)
          return
        end

        # Split by comma for index
        parts = text.split(',', 2)
        address_expr = parts[0]
        index_and_field = parts[1]

        # Tokenize address expression
        if address_expr && !address_expr.empty?
          tokenize_expression(address_expr, line_num, col)
          col += address_expr.length + 1
        end

        # Tokenize index and field if present
        if index_and_field
          # Check for field spec in parens
          if index_and_field =~ /^(\d+)\((.+)\)$/
            # Index with field: 1(2:5)
            @tokens << Token.new(:comma, ',', line_num, col - 1)
            @tokens << Token.new(:index, $1, line_num, col)
            @tokens << Token.new(:lparen, '(', line_num, col + $1.length)
            tokenize_field_spec($2, line_num, col + $1.length + 1)
            @tokens << Token.new(:rparen, ')', line_num, col + index_and_field.length - 1)
          elsif index_and_field =~ /^\((.+)\)$/
            # No index, just field: (2:5)
            @tokens << Token.new(:comma, ',', line_num, col - 1)
            @tokens << Token.new(:lparen, '(', line_num, col)
            tokenize_field_spec($1, line_num, col + 1)
            @tokens << Token.new(:rparen, ')', line_num, col + index_and_field.length - 1)
          else
            # Just index, no field
            @tokens << Token.new(:comma, ',', line_num, col - 1)
            @tokens << Token.new(:index, index_and_field.strip, line_num, col)
          end
        end
      end

      def tokenize_expression(expr, line_num, col)
        # Parse arithmetic expression: NUM, SYMBOL, NUM+NUM, SYMBOL-NUM, etc.
        # For now, handle simple cases

        # Remove spaces
        expr = expr.strip

        # Check for expressions with operators first (before simple tokens)
        if expr.include?('+') || (expr.include?('-') && expr.length > 1 && expr[0] != '-')
          # Expression with operators (but not negative number)
          tokenize_expr_with_ops(expr, line_num, col)
        elsif expr =~ /^[A-Z][A-Z0-9]*$/
          # Symbol
          @tokens << Token.new(:symbol, expr, line_num, col)
        elsif expr =~ /^-?\d+$/
          # Number (including negative)
          @tokens << Token.new(:number, expr.to_i, line_num, col)
        elsif expr == '*'
          # Current address (single *)
          @tokens << Token.new(:current_address, '*', line_num, col)
        else
          # Unknown, treat as symbol
          @tokens << Token.new(:symbol, expr, line_num, col)
        end
      end

      def tokenize_expr_with_ops(expr, line_num, col)
        # Split by + or - (but keep the operators)
        parts = expr.split(/([+\-])/)

        offset = 0
        parts.each do |part|
          next if part.empty?

          if part == '+'
            @tokens << Token.new(:plus, '+', line_num, col + offset)
          elsif part == '-'
            @tokens << Token.new(:minus, '-', line_num, col + offset)
          elsif part =~ /^[A-Z][A-Z0-9]*$/
            @tokens << Token.new(:symbol, part, line_num, col + offset)
          elsif part =~ /^\d+$/
            @tokens << Token.new(:number, part.to_i, line_num, col + offset)
          elsif part == '*'
            @tokens << Token.new(:current_address, '*', line_num, col + offset)
          end

          offset += part.length
        end
      end

      def tokenize_field_spec(spec, line_num, col)
        # Field spec: L:R or just a number
        if spec =~ /^(\d+):(\d+)$/
          @tokens << Token.new(:number, $1.to_i, line_num, col)
          @tokens << Token.new(:colon, ':', line_num, col + $1.length)
          @tokens << Token.new(:number, $2.to_i, line_num, col + $1.length + 1)
        else
          @tokens << Token.new(:number, spec.to_i, line_num, col)
        end
      end

      def find_comment_start(text)
        # Find comment start (not inside quotes)
        # Comments can be:
        # 1. Text after * (if preceded by whitespace)
        # 2. Text after whitespace following a complete token (MIXAL convention)
        #
        # Strategy: Find the first position after a complete token where whitespace begins.
        # A complete token is a sequence of non-space characters not containing operators
        # within the address field (like + or -)
        in_string = false
        prev_char = nil
        in_token = false

        text.each_char.with_index do |char, i|
          if char == '"' || char == "'"
            in_string = !in_string
          elsif !in_string
            # Check for * as comment marker
            if char == '*' && i > 0 && text[i-1] =~ /\s/
              return i
            end

            # Track when we're in a token (non-space characters)
            if char =~ /\S/
              in_token = true
            elsif in_token && char =~ /\s/
              # We've hit the end of a token (space after non-space)
              # Everything from here on is a comment
              return i
            end
          end
          prev_char = char
        end
        nil
      end

      def is_operation?(token)
        # Check if token looks like an operation
        # Operations are typically all uppercase
        return false if token.nil? || token.empty?

        # Known operations and pseudo-ops
        operations = %w[
          LDA LDX LD1 LD2 LD3 LD4 LD5 LD6
          LDAN LDXN LD1N LD2N LD3N LD4N LD5N LD6N
          STA STX ST1 ST2 ST3 ST4 ST5 ST6 STJ STZ
          ADD SUB MUL DIV
          ENTA ENTX ENT1 ENT2 ENT3 ENT4 ENT5 ENT6
          ENNA ENNX ENN1 ENN2 ENN3 ENN4 ENN5 ENN6
          INCA INCX INC1 INC2 INC3 INC4 INC5 INC6
          DECA DECX DEC1 DEC2 DEC3 DEC4 DEC5 DEC6
          CMPA CMPX CMP1 CMP2 CMP3 CMP4 CMP5 CMP6
          JMP JSJ JOV JNOV JL JE JG JGE JNE JLE
          JAN JAZ JAP JANN JANZ JANP
          JXN JXZ JXP JXNN JXNZ JXNP
          J1N J1Z J1P J1NN J1NZ J1NP
          J2N J2Z J2P J2NN J2NZ J2NP
          J3N J3Z J3P J3NN J3NZ J3NP
          J4N J4Z J4P J4NN J4NZ J4NP
          J5N J5Z J5P J5NN J5NZ J5NP
          J6N J6Z J6P J6NN J6NZ J6NP
          SLA SRA SLAX SRAX SLC SRC
          MOVE NUM CHAR HLT
          IN OUT IOC JBUS JRED
          NOP
          ORIG EQU END CON ALF
        ]

        operations.include?(token.upcase)
      end
    end
  end
end
