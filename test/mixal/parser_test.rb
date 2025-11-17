# frozen_string_literal: true

RSpec.describe Taocp::Mixal::Parser do
  let(:parser_class) { Taocp::Mixal::Parser }
  let(:lexer_class) { Taocp::Mixal::Lexer }

  describe "basic instruction parsing" do
    it "parses a simple instruction" do
      source = "LDA 1000"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast.length).to eq(1)
      expect(ast[0]).to be_a(Taocp::Mixal::Parser::Instruction)
      expect(ast[0].operation).to eq("LDA")
      expect(ast[0].address).to eq(1000)
      expect(ast[0].label).to be_nil
    end

    it "parses instruction with label" do
      source = "START LDA 2000"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].label).to eq("START")
      expect(ast[0].operation).to eq("LDA")
      expect(ast[0].address).to eq(2000)
    end

    it "parses instruction with symbolic address" do
      source = "JMP LOOP"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].operation).to eq("JMP")
      expect(ast[0].address).to eq("LOOP")
    end

    it "parses instruction with no operand" do
      source = "HLT"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].operation).to eq("HLT")
      expect(ast[0].address).to be_nil
    end
  end

  describe "address field parsing" do
    it "parses instruction with index" do
      source = "LDA 1000,1"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq(1000)
      expect(ast[0].index).to eq(1)
    end

    it "parses instruction with field specification" do
      source = "LDA 1000(1:5)"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq(1000)
      expect(ast[0].field).to eq("1:5")
    end

    it "parses instruction with index and field" do
      source = "LDA 1000,2(3:4)"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq(1000)
      expect(ast[0].index).to eq(2)
      expect(ast[0].field).to eq("3:4")
    end

    it "parses instruction with single field value" do
      source = "LDA 1000(5)"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq(1000)
      expect(ast[0].field).to eq("5")
    end
  end

  describe "expression parsing" do
    it "parses addition expression" do
      source = "LDA START+10"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq("START+10")
    end

    it "parses subtraction expression" do
      source = "JMP END-5"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq("END-5")
    end

    it "parses current address expression" do
      source = "JMP *+2"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq("*+2")
    end
  end

  describe "literal parsing" do
    it "parses literal constant" do
      source = "LDA =100="
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].address).to eq("=100=")
    end
  end

  describe "pseudo-operation parsing" do
    it "parses ORIG directive" do
      source = "ORIG 1000"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0]).to be_a(Taocp::Mixal::Parser::PseudoOp)
      expect(ast[0].operation).to eq("ORIG")
      expect(ast[0].value).to eq(1000)
    end

    it "parses EQU directive" do
      source = "SIZE EQU 100"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].label).to eq("SIZE")
      expect(ast[0].operation).to eq("EQU")
      expect(ast[0].value).to eq(100)
    end

    it "parses CON directive" do
      source = "VALUE CON 12345"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].label).to eq("VALUE")
      expect(ast[0].operation).to eq("CON")
      expect(ast[0].value).to eq(12345)
    end

    it "parses CON with symbolic value" do
      source = "PTR CON BUFFER"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].value).to eq("BUFFER")
    end

    it "parses ALF directive" do
      source = "ALF HELLO"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].operation).to eq("ALF")
      expect(ast[0].value).to eq("HELLO")
    end

    it "parses END directive" do
      source = "END START"
      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].operation).to eq("END")
      expect(ast[0].value).to eq("START")
    end
  end

  describe "multi-line program parsing" do
    it "parses a simple program" do
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
      ast = parser_class.parse(tokens)

      # Should have 6 instructions (excluding comment line)
      expect(ast.length).to eq(6)

      # Check first instruction
      expect(ast[0].label).to eq("START")
      expect(ast[0].operation).to eq("LDA")
      expect(ast[0].address).to eq("VALUE")

      # Check second instruction
      expect(ast[1].operation).to eq("STA")
      expect(ast[1].address).to eq("RESULT")

      # Check HLT
      expect(ast[2].operation).to eq("HLT")

      # Check CON directives
      expect(ast[3]).to be_a(Taocp::Mixal::Parser::PseudoOp)
      expect(ast[3].label).to eq("VALUE")
      expect(ast[3].value).to eq(100)

      expect(ast[4].label).to eq("RESULT")
      expect(ast[4].value).to eq(0)

      # Check END
      expect(ast[5].operation).to eq("END")
      expect(ast[5].value).to eq("START")
    end

    it "tracks line numbers" do
      source = <<~MIXAL
        LDA 1000
        STA 2000
        HLT
      MIXAL

      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast[0].line).to eq(1)
      expect(ast[1].line).to eq(2)
      expect(ast[2].line).to eq(3)
    end
  end

  describe "complex programs" do
    it "parses factorial program" do
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

      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast.length).to be > 8

      # Check ORIG
      orig = ast.find { |node| node.is_a?(Taocp::Mixal::Parser::PseudoOp) && node.operation == "ORIG" }
      expect(orig.value).to eq(0)

      # Check LOOP label
      loop_inst = ast.find { |node| node.label == "LOOP" }
      expect(loop_inst).not_to be_nil
      expect(loop_inst.operation).to eq("MUL")

      # Check literal
      cmp_inst = ast.find { |node| node.operation == "CMPA" }
      expect(cmp_inst.address).to eq("=0=")
    end

    it "parses program with all address modes" do
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

      tokens = lexer_class.tokenize(source)
      ast = parser_class.parse(tokens)

      expect(ast.length).to eq(8)

      expect(ast[0].address).to eq(1000)
      expect(ast[0].index).to be_nil
      expect(ast[0].field).to be_nil

      expect(ast[1].address).to eq(1000)
      expect(ast[1].index).to eq(1)

      expect(ast[2].address).to eq(1000)
      expect(ast[2].field).to eq("1:5")

      expect(ast[3].address).to eq(1000)
      expect(ast[3].index).to eq(2)
      expect(ast[3].field).to eq("3:4")

      expect(ast[4].address).to eq("SYMBOL")
      expect(ast[5].address).to eq("SYMBOL+10")
      expect(ast[6].address).to eq("*+2")
      expect(ast[7].address).to eq("=99=")
    end
  end
end
