# frozen_string_literal: true

require "test_helper"

class MixalParserTest < Minitest::Test
  def setup
    @parser_class = Taocp::Mixal::Parser
    @lexer_class = Taocp::Mixal::Lexer
  end

  # Basic instruction parsing tests
  def test_parses_a_simple_instruction
    source = "LDA 1000"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal 1, ast.length
    assert_instance_of Taocp::Mixal::Parser::Instruction, ast[0]
    assert_equal "LDA", ast[0].operation
    assert_equal 1000, ast[0].address
    assert_nil ast[0].label
  end

  def test_parses_instruction_with_label
    source = "START LDA 2000"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "START", ast[0].label
    assert_equal "LDA", ast[0].operation
    assert_equal 2000, ast[0].address
  end

  def test_parses_instruction_with_symbolic_address
    source = "JMP LOOP"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "JMP", ast[0].operation
    assert_equal "LOOP", ast[0].address
  end

  def test_parses_instruction_with_no_operand
    source = "HLT"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "HLT", ast[0].operation
    assert_nil ast[0].address
  end

  # Address field parsing tests
  def test_parses_instruction_with_index
    source = "LDA 1000,1"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal 1000, ast[0].address
    assert_equal 1, ast[0].index
  end

  def test_parses_instruction_with_field_specification
    source = "LDA 1000(1:5)"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal 1000, ast[0].address
    assert_equal "1:5", ast[0].field
  end

  def test_parses_instruction_with_index_and_field
    source = "LDA 1000,2(3:4)"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal 1000, ast[0].address
    assert_equal 2, ast[0].index
    assert_equal "3:4", ast[0].field
  end

  def test_parses_instruction_with_single_field_value
    source = "LDA 1000(5)"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal 1000, ast[0].address
    assert_equal "5", ast[0].field
  end

  # Expression parsing tests
  def test_parses_addition_expression
    source = "LDA START+10"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "START+10", ast[0].address
  end

  def test_parses_subtraction_expression
    source = "JMP END-5"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "END-5", ast[0].address
  end

  def test_parses_current_address_expression
    source = "JMP *+2"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "*+2", ast[0].address
  end

  # Literal parsing tests
  def test_parses_literal_constant
    source = "LDA =100="
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "=100=", ast[0].address
  end

  # Pseudo-operation parsing tests
  def test_parses_orig_directive
    source = "ORIG 1000"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_instance_of Taocp::Mixal::Parser::PseudoOp, ast[0]
    assert_equal "ORIG", ast[0].operation
    assert_equal 1000, ast[0].value
  end

  def test_parses_equ_directive
    source = "SIZE EQU 100"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "SIZE", ast[0].label
    assert_equal "EQU", ast[0].operation
    assert_equal 100, ast[0].value
  end

  def test_parses_con_directive
    source = "VALUE CON 12345"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "VALUE", ast[0].label
    assert_equal "CON", ast[0].operation
    assert_equal 12345, ast[0].value
  end

  def test_parses_con_with_symbolic_value
    source = "PTR CON BUFFER"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "BUFFER", ast[0].value
  end

  def test_parses_alf_directive
    source = "ALF HELLO"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "ALF", ast[0].operation
    assert_equal "HELLO", ast[0].value
  end

  def test_parses_end_directive
    source = "END START"
    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal "END", ast[0].operation
    assert_equal "START", ast[0].value
  end

  # Multi-line program parsing tests
  def test_parses_a_simple_program
    source = <<~MIXAL
      * Simple program
      START LDA VALUE
            STA RESULT
            HLT
      VALUE CON 100
      RESULT CON 0
            END START
    MIXAL

    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    # Should have 6 instructions (excluding comment line)
    assert_equal 6, ast.length

    # Check first instruction
    assert_equal "START", ast[0].label
    assert_equal "LDA", ast[0].operation
    assert_equal "VALUE", ast[0].address

    # Check second instruction
    assert_equal "STA", ast[1].operation
    assert_equal "RESULT", ast[1].address

    # Check HLT
    assert_equal "HLT", ast[2].operation

    # Check CON directives
    assert_instance_of Taocp::Mixal::Parser::PseudoOp, ast[3]
    assert_equal "VALUE", ast[3].label
    assert_equal 100, ast[3].value

    assert_equal "RESULT", ast[4].label
    assert_equal 0, ast[4].value

    # Check END
    assert_equal "END", ast[5].operation
    assert_equal "START", ast[5].value
  end

  def test_tracks_line_numbers
    source = <<~MIXAL
      LDA 1000
      STA 2000
      HLT
    MIXAL

    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal 1, ast[0].line
    assert_equal 2, ast[1].line
    assert_equal 3, ast[2].line
  end

  # Complex programs tests
  def test_parses_factorial_program
    source = <<~MIXAL
      * Factorial of 6
            ORIG 0
      START ENTA 6
            STA N
            ENTA 1
      LOOP  MUL N
            LDA N
            DECA 1
            STA N
            CMPA =0=
            JG LOOP
            HLT
      N     CON 0
            END START
    MIXAL

    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_operator ast.length, :>, 8

    # Check ORIG
    orig = ast.find { |node| node.is_a?(Taocp::Mixal::Parser::PseudoOp) && node.operation == "ORIG" }
    assert_equal 0, orig.value

    # Check LOOP label
    loop_inst = ast.find { |node| node.label == "LOOP" }
    refute_nil loop_inst
    assert_equal "MUL", loop_inst.operation

    # Check literal
    cmp_inst = ast.find { |node| node.operation == "CMPA" }
    assert_equal "=0=", cmp_inst.address
  end

  def test_parses_program_with_all_address_modes
    source = <<~MIXAL
      L1    LDA 1000
      L2    LDA 1000,1
      L3    LDA 1000(1:5)
      L4    LDA 1000,2(3:4)
      L5    LDA SYMBOL
      L6    LDA SYMBOL+10
      L7    LDA *+2
      L8    LDA =99=
    MIXAL

    tokens = @lexer_class.tokenize(source)
    ast = @parser_class.parse(tokens)

    assert_equal 8, ast.length

    assert_equal 1000, ast[0].address
    assert_nil ast[0].index
    assert_nil ast[0].field

    assert_equal 1000, ast[1].address
    assert_equal 1, ast[1].index

    assert_equal 1000, ast[2].address
    assert_equal "1:5", ast[2].field

    assert_equal 1000, ast[3].address
    assert_equal 2, ast[3].index
    assert_equal "3:4", ast[3].field

    assert_equal "SYMBOL", ast[4].address
    assert_equal "SYMBOL+10", ast[5].address
    assert_equal "*+2", ast[6].address
    assert_equal "=99=", ast[7].address
  end
end
