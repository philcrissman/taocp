# frozen_string_literal: true

require "test_helper"

class MixalLexerTest < Minitest::Test
  def setup
    @lexer_class = Taocp::Mixal::Lexer
  end

  # Basic tokenization tests
  def test_tokenizes_a_simple_instruction
    source = "LDA 1000"
    tokens = @lexer_class.tokenize(source)

    assert_equal 2, tokens.length
    assert_equal :operation, tokens[0].type
    assert_equal "LDA", tokens[0].value
    assert_equal :number, tokens[1].type
    assert_equal 1000, tokens[1].value
  end

  def test_tokenizes_instruction_with_label
    source = "START LDA 2000"
    tokens = @lexer_class.tokenize(source)

    assert_equal 3, tokens.length
    assert_equal :label, tokens[0].type
    assert_equal "START", tokens[0].value
    assert_equal :operation, tokens[1].type
    assert_equal "LDA", tokens[1].value
    assert_equal :number, tokens[2].type
    assert_equal 2000, tokens[2].value
  end

  def test_tokenizes_empty_lines
    source = "\n\n"
    tokens = @lexer_class.tokenize(source)

    assert_equal 0, tokens.length
  end

  def test_tokenizes_full_line_comments
    source = "* This is a comment"
    tokens = @lexer_class.tokenize(source)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "* This is a comment", tokens[0].value
  end

  # Address field tokenization tests
  def test_tokenizes_instruction_with_index
    source = "LDA 1000,1"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    assert_includes types, :operation
    assert_includes types, :number
    assert_includes types, :comma
    assert_includes types, :index
    assert_equal "1", tokens.find { |t| t.type == :index }.value
  end

  def test_tokenizes_instruction_with_field_specification
    source = "LDA 1000(1:5)"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    # No comma because there's no index - just address with field spec
    assert_includes types, :operation
    assert_includes types, :number
    assert_includes types, :lparen
    assert_includes types, :colon
    assert_includes types, :rparen
    refute_includes types, :comma
  end

  def test_tokenizes_instruction_with_index_and_field
    source = "LDA 1000,1(2:4)"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    assert_includes types, :operation
    assert_includes types, :number
    assert_includes types, :comma
    assert_includes types, :index
    assert_includes types, :lparen
    assert_includes types, :colon
    assert_includes types, :rparen
  end

  def test_tokenizes_symbolic_address
    source = "JMP LOOP"
    tokens = @lexer_class.tokenize(source)

    assert_equal 2, tokens.length
    assert_equal :operation, tokens[0].type
    assert_equal :symbol, tokens[1].type
    assert_equal "LOOP", tokens[1].value
  end

  # Expression tokenization tests
  def test_tokenizes_addition_expression
    source = "LDA START+10"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    assert_includes types, :operation
    assert_includes types, :symbol
    assert_includes types, :plus
    assert_includes types, :number
    assert_equal "START", tokens.find { |t| t.type == :symbol }.value
    assert_equal 10, tokens.find { |t| t.type == :number }.value
  end

  def test_tokenizes_subtraction_expression
    source = "JMP END-5"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    assert_includes types, :operation
    assert_includes types, :symbol
    assert_includes types, :minus
    assert_includes types, :number
  end

  def test_tokenizes_current_address
    source = "JMP *+2"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    assert_includes types, :operation
    assert_includes types, :current_address
    assert_includes types, :plus
    assert_includes types, :number
  end

  # Literal tokenization tests
  def test_tokenizes_literal_constant
    source = "LDA =5="
    tokens = @lexer_class.tokenize(source)

    assert_equal 2, tokens.length
    assert_equal :literal, tokens[1].type
    assert_equal "=5=", tokens[1].value
  end

  def test_tokenizes_literal_with_additional_address
    source = "LDA =100=,1"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    assert_includes types, :operation
    assert_includes types, :literal
    assert_includes types, :comma
    assert_includes types, :index
  end

  # Comment tokenization tests
  def test_tokenizes_inline_comment_after_instruction
    source = "LDA 1000   * Load accumulator"
    tokens = @lexer_class.tokenize(source)

    assert_equal :comment, tokens.last.type
    assert_equal "* Load accumulator", tokens.last.value
  end

  def test_tokenizes_instruction_without_comment
    source = "ADD 2000"
    tokens = @lexer_class.tokenize(source)

    assert tokens.none? { |t| t.type == :comment }
  end

  # Pseudo-operation tokenization tests
  def test_tokenizes_orig_directive
    source = "ORIG 1000"
    tokens = @lexer_class.tokenize(source)

    assert_equal :operation, tokens[0].type
    assert_equal "ORIG", tokens[0].value
    assert_equal :number, tokens[1].type
    assert_equal 1000, tokens[1].value
  end

  def test_tokenizes_equ_directive
    source = "SIZE EQU 100"
    tokens = @lexer_class.tokenize(source)

    assert_equal :label, tokens[0].type
    assert_equal "SIZE", tokens[0].value
    assert_equal :operation, tokens[1].type
    assert_equal "EQU", tokens[1].value
    assert_equal :number, tokens[2].type
    assert_equal 100, tokens[2].value
  end

  def test_tokenizes_con_directive
    source = "VALUE CON 12345"
    tokens = @lexer_class.tokenize(source)

    assert_equal :label, tokens[0].type
    assert_equal :operation, tokens[1].type
    assert_equal "CON", tokens[1].value
    assert_equal :number, tokens[2].type
  end

  def test_tokenizes_alf_directive
    source = 'ALF HELLO'
    tokens = @lexer_class.tokenize(source)

    assert_equal :operation, tokens[0].type
    assert_equal "ALF", tokens[0].value
    assert_equal :alf_value, tokens[1].type
    assert_equal "HELLO", tokens[1].value
  end

  def test_tokenizes_end_directive
    source = "END START"
    tokens = @lexer_class.tokenize(source)

    assert_equal :operation, tokens[0].type
    assert_equal "END", tokens[0].value
    assert_equal :symbol, tokens[1].type
    assert_equal "START", tokens[1].value
  end

  # Multi-line program tokenization tests
  def test_tokenizes_a_simple_program
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

    # Should have tokens for: comment, label+operation+symbol, operation+symbol, operation,
    # label+operation+number, label+operation+number, operation+symbol
    assert_operator tokens.length, :>, 10

    # Check first line (comment)
    assert_equal :comment, tokens[0].type

    # Check label START exists
    labels = tokens.select { |t| t.type == :label }
    assert_includes labels.map(&:value), "START"
    assert_includes labels.map(&:value), "VALUE"
    assert_includes labels.map(&:value), "RESULT"

    # Check operations
    operations = tokens.select { |t| t.type == :operation }
    assert_includes operations.map(&:value), "LDA"
    assert_includes operations.map(&:value), "STA"
    assert_includes operations.map(&:value), "HLT"
    assert_includes operations.map(&:value), "CON"
    assert_includes operations.map(&:value), "END"
  end

  def test_tracks_line_numbers_correctly
    source = <<~MIXAL
      LDA 1000
      STA 2000
      HLT
    MIXAL

    tokens = @lexer_class.tokenize(source)

    # First instruction on line 1
    assert_equal 1, tokens[0].line

    # Second instruction on line 2
    sta_token = tokens.find { |t| t.value == "STA" }
    assert_equal 2, sta_token.line

    # Third instruction on line 3
    hlt_token = tokens.find { |t| t.value == "HLT" }
    assert_equal 3, hlt_token.line
  end

  # Edge cases tests
  def test_handles_instruction_with_no_operand
    source = "HLT"
    tokens = @lexer_class.tokenize(source)

    assert_equal 1, tokens.length
    assert_equal :operation, tokens[0].type
    assert_equal "HLT", tokens[0].value
  end

  def test_handles_multiple_spaces_between_tokens
    source = "LDA     1000"
    tokens = @lexer_class.tokenize(source)

    assert_equal 2, tokens.length
    assert_equal "LDA", tokens[0].value
    assert_equal 1000, tokens[1].value
  end

  def test_handles_negative_numbers
    source = "LDA -50"
    tokens = @lexer_class.tokenize(source)

    assert_equal :number, tokens[1].type
    assert_equal(-50, tokens[1].value)
  end

  def test_handles_field_specification_with_single_number
    source = "LDA 1000(5)"
    tokens = @lexer_class.tokenize(source)

    types = tokens.map(&:type)
    # No comma because there's no index - just address with field spec
    assert_includes types, :operation
    assert_includes types, :number
    assert_includes types, :lparen
    assert_includes types, :rparen
    refute_includes types, :comma
  end

  # All instruction types tests
  def test_recognizes_load_instructions
    ["LDA", "LDX", "LD1", "LD2", "LD3", "LD4", "LD5", "LD6"].each do |op|
      tokens = @lexer_class.tokenize("#{op} 1000")
      assert_equal :operation, tokens[0].type
      assert_equal op, tokens[0].value
    end
  end

  def test_recognizes_store_instructions
    ["STA", "STX", "ST1", "ST2", "STJ", "STZ"].each do |op|
      tokens = @lexer_class.tokenize("#{op} 1000")
      assert_equal :operation, tokens[0].type
    end
  end

  def test_recognizes_arithmetic_instructions
    ["ADD", "SUB", "MUL", "DIV"].each do |op|
      tokens = @lexer_class.tokenize("#{op} 1000")
      assert_equal :operation, tokens[0].type
    end
  end

  def test_recognizes_address_transfer_instructions
    ["ENTA", "ENT1", "INCA", "INC1", "DECA", "DEC1"].each do |op|
      tokens = @lexer_class.tokenize("#{op} 1000")
      assert_equal :operation, tokens[0].type
    end
  end

  def test_recognizes_comparison_instructions
    ["CMPA", "CMPX", "CMP1"].each do |op|
      tokens = @lexer_class.tokenize("#{op} 1000")
      assert_equal :operation, tokens[0].type
    end
  end

  def test_recognizes_jump_instructions
    ["JMP", "JAN", "JAZ", "JL", "JE", "JG"].each do |op|
      tokens = @lexer_class.tokenize("#{op} 1000")
      assert_equal :operation, tokens[0].type
    end
  end

  def test_recognizes_shift_instructions
    ["SLA", "SRA", "SLAX", "SRAX", "SLC", "SRC"].each do |op|
      tokens = @lexer_class.tokenize("#{op} 1")
      assert_equal :operation, tokens[0].type
    end
  end

  def test_recognizes_miscellaneous_instructions
    ["MOVE", "NUM", "CHAR", "HLT", "NOP"].each do |op|
      tokens = @lexer_class.tokenize("#{op}")
      assert_equal :operation, tokens[0].type
    end
  end
end
