# frozen_string_literal: true

module Quackers
  module Mixal
    # MIXAL assembler - converts MIXAL source to MIX machine code
    class Assembler
      class Error < Mixal::Error; end

      attr_reader :symbol_table, :instructions, :memory, :start_address

      def initialize
        @symbol_table = SymbolTable.new
        @instructions = []
        @memory = Mix::Memory.new
        @location = 0
        @start_address = nil
        @literals = {}  # Track literal constants
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

        # Second pass: generate machine code
        second_pass

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

      # Second pass: generate machine code
      def second_pass
        @instructions.each do |inst_info|
          node = inst_info[:node]
          location = inst_info[:location]

          case node
          when Parser::PseudoOp
            process_pseudo_op_second_pass(node, location)
          when Parser::Instruction
            process_instruction_second_pass(node, location)
          end
        end

        # Process start address if set
        if @start_address
          @start_address = evaluate_expression(@start_address, 0)
        end
      end

      def process_pseudo_op_second_pass(node, location)
        case node.operation.upcase
        when 'CON'
          # Generate constant word
          value = evaluate_expression(node.value, location)
          @memory[location] = Mix::Word.from_i(value)

        when 'ALF'
          # Generate alphanumeric word from 5 characters
          text = node.value.to_s
          bytes = [0, 0, 0, 0, 0]

          text.chars.first(5).each_with_index do |char, i|
            bytes[i] = Mix::Character.char_to_code(char)
          end

          @memory[location] = Mix::Word.new(sign: 1, bytes: bytes)
        end
      end

      def process_instruction_second_pass(node, location)
        # Get opcode and field
        opcode = get_opcode(node.operation)
        field = get_field(node.operation, node.field)

        # Evaluate address
        address_value = 0
        sign = 1

        if node.address
          # Handle literals
          if node.address.to_s =~ /^=(.+)=$/
            # Literal constant - for now, just extract the value
            literal_value = $1.to_i
            address_value = literal_value.abs
            sign = literal_value < 0 ? -1 : 1
          else
            # Regular address expression
            address_value = evaluate_expression(node.address, location)
            if address_value < 0
              sign = -1
              address_value = address_value.abs
            end
          end
        end

        # Get index (default 0)
        index = node.index ? node.index.to_i : 0

        # Create instruction
        inst = Mix::Instruction.new(
          address: address_value,
          index: index,
          field: field,
          opcode: opcode,
          sign: sign
        )

        @memory[location] = inst.to_word
      end

      # Opcode mapping table
      OPCODE_MAP = {
        'NOP' => [Mix::Instruction::NOP, 0],
        'ADD' => [Mix::Instruction::ADD, 5],
        'SUB' => [Mix::Instruction::SUB, 5],
        'MUL' => [Mix::Instruction::MUL, 5],
        'DIV' => [Mix::Instruction::DIV, 5],
        'NUM' => [Mix::Instruction::NUM, 0],
        'CHAR' => [Mix::Instruction::CHAR, 1],
        'HLT' => [Mix::Instruction::HLT, 2],
        'SLA' => [Mix::Instruction::SLA, 0],
        'SRA' => [Mix::Instruction::SRA, 1],
        'SLAX' => [Mix::Instruction::SLAX, 2],
        'SRAX' => [Mix::Instruction::SRAX, 3],
        'SLC' => [Mix::Instruction::SLC, 4],
        'SRC' => [Mix::Instruction::SRC, 5],
        'MOVE' => [Mix::Instruction::MOVE, 1],
        'LDA' => [Mix::Instruction::LDA, 5],
        'LD1' => [Mix::Instruction::LD1, 5],
        'LD2' => [Mix::Instruction::LD2, 5],
        'LD3' => [Mix::Instruction::LD3, 5],
        'LD4' => [Mix::Instruction::LD4, 5],
        'LD5' => [Mix::Instruction::LD5, 5],
        'LD6' => [Mix::Instruction::LD6, 5],
        'LDX' => [Mix::Instruction::LDX, 5],
        'LDAN' => [Mix::Instruction::LDAN, 5],
        'LD1N' => [Mix::Instruction::LD1N, 5],
        'LD2N' => [Mix::Instruction::LD2N, 5],
        'LD3N' => [Mix::Instruction::LD3N, 5],
        'LD4N' => [Mix::Instruction::LD4N, 5],
        'LD5N' => [Mix::Instruction::LD5N, 5],
        'LD6N' => [Mix::Instruction::LD6N, 5],
        'LDXN' => [Mix::Instruction::LDXN, 5],
        'STA' => [Mix::Instruction::STA, 5],
        'ST1' => [Mix::Instruction::ST1, 5],
        'ST2' => [Mix::Instruction::ST2, 5],
        'ST3' => [Mix::Instruction::ST3, 5],
        'ST4' => [Mix::Instruction::ST4, 5],
        'ST5' => [Mix::Instruction::ST5, 5],
        'ST6' => [Mix::Instruction::ST6, 5],
        'STX' => [Mix::Instruction::STX, 5],
        'STJ' => [Mix::Instruction::STJ, 2],
        'STZ' => [Mix::Instruction::STZ, 5],
        'JBUS' => [Mix::Instruction::JBUS, 0],
        'IOC' => [Mix::Instruction::IOC, 0],
        'IN' => [Mix::Instruction::IN, 0],
        'OUT' => [Mix::Instruction::OUT, 0],
        'JRED' => [Mix::Instruction::JRED, 0],
        'JMP' => [Mix::Instruction::JMP, 0],
        'JSJ' => [Mix::Instruction::JMP, 1],
        'JOV' => [Mix::Instruction::JMP, 2],
        'JNOV' => [Mix::Instruction::JMP, 3],
        'JL' => [Mix::Instruction::JMP, 4],
        'JE' => [Mix::Instruction::JMP, 5],
        'JG' => [Mix::Instruction::JMP, 6],
        'JGE' => [Mix::Instruction::JMP, 7],
        'JNE' => [Mix::Instruction::JMP, 8],
        'JLE' => [Mix::Instruction::JMP, 9],
        'JAN' => [Mix::Instruction::JAN, 0],
        'JAZ' => [Mix::Instruction::JAN, 1],
        'JAP' => [Mix::Instruction::JAN, 2],
        'JANN' => [Mix::Instruction::JAN, 3],
        'JANZ' => [Mix::Instruction::JAN, 4],
        'JANP' => [Mix::Instruction::JAN, 5],
        'INCA' => [Mix::Instruction::INCA, 2],
        'DECA' => [Mix::Instruction::DECA, 3],
        'ENTA' => [Mix::Instruction::ENTA, 0],
        'ENNA' => [Mix::Instruction::ENTA, 1],
        'INC1' => [Mix::Instruction::INC1, 2],
        'DEC1' => [Mix::Instruction::DEC1, 3],
        'ENT1' => [Mix::Instruction::ENT1, 0],
        'ENN1' => [Mix::Instruction::ENN1, 1],
        'INC2' => [Mix::Instruction::INC2, 2],
        'DEC2' => [Mix::Instruction::DEC2, 3],
        'ENT2' => [Mix::Instruction::ENT2, 0],
        'ENN2' => [Mix::Instruction::ENT2, 1],
        'INC3' => [Mix::Instruction::INC3, 2],
        'DEC3' => [Mix::Instruction::DEC3, 3],
        'ENT3' => [Mix::Instruction::ENT3, 0],
        'ENN3' => [Mix::Instruction::ENT3, 1],
        'INC4' => [Mix::Instruction::INC4, 2],
        'DEC4' => [Mix::Instruction::DEC4, 3],
        'ENT4' => [Mix::Instruction::ENT4, 0],
        'ENN4' => [Mix::Instruction::ENT4, 1],
        'INC5' => [Mix::Instruction::INC5, 2],
        'DEC5' => [Mix::Instruction::DEC5, 3],
        'ENT5' => [Mix::Instruction::ENT5, 0],
        'ENN5' => [Mix::Instruction::ENT5, 1],
        'INC6' => [Mix::Instruction::INC6, 2],
        'DEC6' => [Mix::Instruction::DEC6, 3],
        'ENT6' => [Mix::Instruction::ENT6, 0],
        'ENN6' => [Mix::Instruction::ENT6, 1],
        'INCX' => [Mix::Instruction::INCX, 2],
        'DECX' => [Mix::Instruction::DECX, 3],
        'ENTX' => [Mix::Instruction::ENTX, 0],
        'ENNX' => [Mix::Instruction::ENNX, 1],
        'CMPA' => [Mix::Instruction::CMPA, 5],
        'CMP1' => [Mix::Instruction::CMP1, 5],
        'CMP2' => [Mix::Instruction::CMP2, 5],
        'CMP3' => [Mix::Instruction::CMP3, 5],
        'CMP4' => [Mix::Instruction::CMP4, 5],
        'CMP5' => [Mix::Instruction::CMP5, 5],
        'CMP6' => [Mix::Instruction::CMP6, 5],
        'CMPX' => [Mix::Instruction::CMPX, 5],
      }.freeze

      def get_opcode(operation)
        op_upper = operation.upcase
        if OPCODE_MAP.key?(op_upper)
          OPCODE_MAP[op_upper][0]
        else
          raise Error, "Unknown operation: #{operation}"
        end
      end

      def get_field(operation, explicit_field)
        # If field is explicitly specified, parse it
        if explicit_field
          # Parse field specification
          if explicit_field.to_s =~ /^(\d+):(\d+)$/
            # L:R format - encode as 8*L + R
            left = $1.to_i
            right = $2.to_i
            return 8 * left + right
          else
            # Single number
            return explicit_field.to_i
          end
        end

        # Use default field from opcode map
        op_upper = operation.upcase
        if OPCODE_MAP.key?(op_upper)
          OPCODE_MAP[op_upper][1]
        else
          0  # Default field
        end
      end
    end
  end
end
