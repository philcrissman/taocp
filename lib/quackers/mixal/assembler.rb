# frozen_string_literal: true

module Quackers
  module Mixal
    # MIXAL assembler - converts MIXAL source to MIX machine code
    class Assembler
      class Error < Mixal::Error; end

      attr_reader :symbol_table, :instructions

      def initialize
        @symbol_table = SymbolTable.new
        @instructions = []
        @location = 0
        @start_address = nil
      end

      # Assemble MIXAL source code
      def self.assemble(source)
        new.assemble(source)
      end

      # Full assembly process
      def assemble(source)
        # Lex
        tokens = Lexer.tokenize(source)
        
        # Parse
        ast = Parser.parse(tokens)
        
        # First pass: build symbol table
        first_pass(ast)
        
        # Second pass: generate machine code (TODO)
        # second_pass(ast)
        
        self
      end

      private

      # First pass: build symbol table and assign addresses
      def first_pass(ast)
        @location = 0
        @instructions = []
        
        ast.each do |node|
          process_node_first_pass(node)
        end
      end

      def process_node_first_pass(node)
        case node
        when Parser::PseudoOp
          process_pseudo_op_first_pass(node)
        when Parser::Instruction
          process_instruction_first_pass(node)
        end
      end

      def process_pseudo_op_first_pass(node)
        case node.operation.upcase
        when 'ORIG'
          # Set location counter
          value = evaluate_expression(node.value, @location)
          @location = value
          
        when 'EQU'
          # Define symbol
          if node.label.nil?
            raise Error, "EQU requires a label (line #{node.line})"
          end
          value = evaluate_expression(node.value, @location)
          @symbol_table.define(node.label, value)
          
        when 'CON'
          # Define label if present (and not empty)
          if node.label && !node.label.empty?
            @symbol_table.define(node.label, @location)
          end
          # Store instruction for second pass
          @instructions << { node: node, location: @location }
          @location += 1

        when 'ALF'
          # Define label if present (and not empty)
          if node.label && !node.label.empty?
            @symbol_table.define(node.label, @location)
          end
          @instructions << { node: node, location: @location }
          @location += 1
          
        when 'END'
          # Mark start address
          if node.value
            @start_address = node.value
          end
        end
      end

      def process_instruction_first_pass(node)
        # Define label if present (and not empty)
        if node.label && !node.label.empty?
          @symbol_table.define(node.label, @location)
        end

        # Store instruction for second pass
        @instructions << { node: node, location: @location }

        # Increment location counter
        @location += 1
      end

      def evaluate_expression(expr, current_location)
        return nil if expr.nil?
        
        # Use symbol table to evaluate with current location context
        @symbol_table.evaluate_with_location(expr, current_location)
      end
    end
  end
end
