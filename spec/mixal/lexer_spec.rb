# frozen_string_literal: true

RSpec.describe Quackers::Mixal::Lexer do
  let(:lexer_class) { Quackers::Mixal::Lexer }

  describe "basic tokenization" do
    it "tokenizes a simple instruction" do
      source = "LDA 1000"
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(2)
      expect(tokens[0].type).to eq(:operation)
      expect(tokens[0].value).to eq("LDA")
      expect(tokens[1].type).to eq(:number)
      expect(tokens[1].value).to eq(1000)
    end

    it "tokenizes instruction with label" do
      source = "START LDA 2000"
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(3)
      expect(tokens[0].type).to eq(:label)
      expect(tokens[0].value).to eq("START")
      expect(tokens[1].type).to eq(:operation)
      expect(tokens[1].value).to eq("LDA")
      expect(tokens[2].type).to eq(:number)
      expect(tokens[2].value).to eq(2000)
    end

    it "tokenizes empty lines" do
      source = "\n\n"
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(0)
    end

    it "tokenizes full-line comments" do
      source = "* This is a comment"
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(1)
      expect(tokens[0].type).to eq(:comment)
      expect(tokens[0].value).to eq("* This is a comment")
    end
  end

  describe "address field tokenization" do
    it "tokenizes instruction with index" do
      source = "LDA 1000,1"
      tokens = lexer_class.tokenize(source)

      expect(tokens.map(&:type)).to include(:operation, :number, :comma, :index)
      expect(tokens.find { |t| t.type == :index }.value).to eq("1")
    end

    it "tokenizes instruction with field specification" do
      source = "LDA 1000(1:5)"
      tokens = lexer_class.tokenize(source)

      types = tokens.map(&:type)
      # No comma because there's no index - just address with field spec
      expect(types).to include(:operation, :number, :lparen, :colon, :rparen)
      expect(types).not_to include(:comma)
    end

    it "tokenizes instruction with index and field" do
      source = "LDA 1000,1(2:4)"
      tokens = lexer_class.tokenize(source)

      types = tokens.map(&:type)
      expect(types).to include(:operation, :number, :comma, :index, :lparen, :colon, :rparen)
    end

    it "tokenizes symbolic address" do
      source = "JMP LOOP"
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(2)
      expect(tokens[0].type).to eq(:operation)
      expect(tokens[1].type).to eq(:symbol)
      expect(tokens[1].value).to eq("LOOP")
    end
  end

  describe "expression tokenization" do
    it "tokenizes addition expression" do
      source = "LDA START+10"
      tokens = lexer_class.tokenize(source)

      expect(tokens.map(&:type)).to include(:operation, :symbol, :plus, :number)
      expect(tokens.find { |t| t.type == :symbol }.value).to eq("START")
      expect(tokens.find { |t| t.type == :number }.value).to eq(10)
    end

    it "tokenizes subtraction expression" do
      source = "JMP END-5"
      tokens = lexer_class.tokenize(source)

      expect(tokens.map(&:type)).to include(:operation, :symbol, :minus, :number)
    end

    it "tokenizes current address (*)" do
      source = "JMP *+2"
      tokens = lexer_class.tokenize(source)

      expect(tokens.map(&:type)).to include(:operation, :current_address, :plus, :number)
    end
  end

  describe "literal tokenization" do
    it "tokenizes literal constant" do
      source = "LDA =5="
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(2)
      expect(tokens[1].type).to eq(:literal)
      expect(tokens[1].value).to eq("=5=")
    end

    it "tokenizes literal with additional address" do
      source = "LDA =100=,1"
      tokens = lexer_class.tokenize(source)

      expect(tokens.map(&:type)).to include(:operation, :literal, :comma, :index)
    end
  end

  describe "comment tokenization" do
    it "tokenizes inline comment after instruction" do
      source = "LDA 1000   * Load accumulator"
      tokens = lexer_class.tokenize(source)

      expect(tokens.last.type).to eq(:comment)
      expect(tokens.last.value).to eq("* Load accumulator")
    end

    it "tokenizes instruction without comment" do
      source = "ADD 2000"
      tokens = lexer_class.tokenize(source)

      expect(tokens.none? { |t| t.type == :comment }).to eq(true)
    end
  end

  describe "pseudo-operation tokenization" do
    it "tokenizes ORIG directive" do
      source = "ORIG 1000"
      tokens = lexer_class.tokenize(source)

      expect(tokens[0].type).to eq(:operation)
      expect(tokens[0].value).to eq("ORIG")
      expect(tokens[1].type).to eq(:number)
      expect(tokens[1].value).to eq(1000)
    end

    it "tokenizes EQU directive" do
      source = "SIZE EQU 100"
      tokens = lexer_class.tokenize(source)

      expect(tokens[0].type).to eq(:label)
      expect(tokens[0].value).to eq("SIZE")
      expect(tokens[1].type).to eq(:operation)
      expect(tokens[1].value).to eq("EQU")
      expect(tokens[2].type).to eq(:number)
      expect(tokens[2].value).to eq(100)
    end

    it "tokenizes CON directive" do
      source = "VALUE CON 12345"
      tokens = lexer_class.tokenize(source)

      expect(tokens[0].type).to eq(:label)
      expect(tokens[1].type).to eq(:operation)
      expect(tokens[1].value).to eq("CON")
      expect(tokens[2].type).to eq(:number)
    end

    it "tokenizes ALF directive" do
      source = 'ALF HELLO'
      tokens = lexer_class.tokenize(source)

      expect(tokens[0].type).to eq(:operation)
      expect(tokens[0].value).to eq("ALF")
      expect(tokens[1].type).to eq(:symbol)
      expect(tokens[1].value).to eq("HELLO")
    end

    it "tokenizes END directive" do
      source = "END START"
      tokens = lexer_class.tokenize(source)

      expect(tokens[0].type).to eq(:operation)
      expect(tokens[0].value).to eq("END")
      expect(tokens[1].type).to eq(:symbol)
      expect(tokens[1].value).to eq("START")
    end
  end

  describe "multi-line program tokenization" do
    it "tokenizes a simple program" do
      source = <<~MIXAL
        * Simple program
        START LDA VALUE
              STA RESULT
              HLT
        VALUE CON 100
        RESULT CON 0
              END START
      MIXAL

      tokens = lexer_class.tokenize(source)

      # Should have tokens for: comment, label+operation+symbol, operation+symbol, operation,
      # label+operation+number, label+operation+number, operation+symbol
      expect(tokens.length).to be > 10

      # Check first line (comment)
      expect(tokens[0].type).to eq(:comment)

      # Check label START exists
      labels = tokens.select { |t| t.type == :label }
      expect(labels.map(&:value)).to include("START", "VALUE", "RESULT")

      # Check operations
      operations = tokens.select { |t| t.type == :operation }
      expect(operations.map(&:value)).to include("LDA", "STA", "HLT", "CON", "END")
    end

    it "tracks line numbers correctly" do
      source = <<~MIXAL
        LDA 1000
        STA 2000
        HLT
      MIXAL

      tokens = lexer_class.tokenize(source)

      # First instruction on line 1
      expect(tokens[0].line).to eq(1)

      # Second instruction on line 2
      sta_token = tokens.find { |t| t.value == "STA" }
      expect(sta_token.line).to eq(2)

      # Third instruction on line 3
      hlt_token = tokens.find { |t| t.value == "HLT" }
      expect(hlt_token.line).to eq(3)
    end
  end

  describe "edge cases" do
    it "handles instruction with no operand" do
      source = "HLT"
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(1)
      expect(tokens[0].type).to eq(:operation)
      expect(tokens[0].value).to eq("HLT")
    end

    it "handles multiple spaces between tokens" do
      source = "LDA     1000"
      tokens = lexer_class.tokenize(source)

      expect(tokens.length).to eq(2)
      expect(tokens[0].value).to eq("LDA")
      expect(tokens[1].value).to eq(1000)
    end

    it "handles negative numbers" do
      source = "LDA -50"
      tokens = lexer_class.tokenize(source)

      expect(tokens[1].type).to eq(:number)
      expect(tokens[1].value).to eq(-50)
    end

    it "handles field specification with single number" do
      source = "LDA 1000(5)"
      tokens = lexer_class.tokenize(source)

      types = tokens.map(&:type)
      # No comma because there's no index - just address with field spec
      expect(types).to include(:operation, :number, :lparen, :rparen)
      expect(types).not_to include(:comma)
    end
  end

  describe "all instruction types" do
    it "recognizes load instructions" do
      ["LDA", "LDX", "LD1", "LD2", "LD3", "LD4", "LD5", "LD6"].each do |op|
        tokens = lexer_class.tokenize("#{op} 1000")
        expect(tokens[0].type).to eq(:operation)
        expect(tokens[0].value).to eq(op)
      end
    end

    it "recognizes store instructions" do
      ["STA", "STX", "ST1", "ST2", "STJ", "STZ"].each do |op|
        tokens = lexer_class.tokenize("#{op} 1000")
        expect(tokens[0].type).to eq(:operation)
      end
    end

    it "recognizes arithmetic instructions" do
      ["ADD", "SUB", "MUL", "DIV"].each do |op|
        tokens = lexer_class.tokenize("#{op} 1000")
        expect(tokens[0].type).to eq(:operation)
      end
    end

    it "recognizes address transfer instructions" do
      ["ENTA", "ENT1", "INCA", "INC1", "DECA", "DEC1"].each do |op|
        tokens = lexer_class.tokenize("#{op} 1000")
        expect(tokens[0].type).to eq(:operation)
      end
    end

    it "recognizes comparison instructions" do
      ["CMPA", "CMPX", "CMP1"].each do |op|
        tokens = lexer_class.tokenize("#{op} 1000")
        expect(tokens[0].type).to eq(:operation)
      end
    end

    it "recognizes jump instructions" do
      ["JMP", "JAN", "JAZ", "JL", "JE", "JG"].each do |op|
        tokens = lexer_class.tokenize("#{op} 1000")
        expect(tokens[0].type).to eq(:operation)
      end
    end

    it "recognizes shift instructions" do
      ["SLA", "SRA", "SLAX", "SRAX", "SLC", "SRC"].each do |op|
        tokens = lexer_class.tokenize("#{op} 1")
        expect(tokens[0].type).to eq(:operation)
      end
    end

    it "recognizes miscellaneous instructions" do
      ["MOVE", "NUM", "CHAR", "HLT", "NOP"].each do |op|
        tokens = lexer_class.tokenize("#{op}")
        expect(tokens[0].type).to eq(:operation)
      end
    end
  end
end
