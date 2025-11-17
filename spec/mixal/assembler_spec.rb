# frozen_string_literal: true

RSpec.describe Quackers::Mixal::Assembler do
  let(:assembler) { Quackers::Mixal::Assembler.new }

  describe "first pass - symbol table construction" do
    it "builds symbol table for simple program" do
      source = <<~MIXAL
        START LDA VALUE
              HLT
        VALUE CON 100
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("START")).to eq(0)
      expect(assembler.symbol_table.lookup("VALUE")).to eq(2)
    end

    it "handles ORIG directive" do
      source = <<~MIXAL
              ORIG 1000
        START LDA VALUE
        VALUE CON 100
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("START")).to eq(1000)
      expect(assembler.symbol_table.lookup("VALUE")).to eq(1001)
    end

    it "handles EQU directive" do
      source = <<~MIXAL
        SIZE  EQU 100
        START LDA SIZE
              HLT
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("SIZE")).to eq(100)
      expect(assembler.symbol_table.lookup("START")).to eq(0)
    end

    it "handles EQU with symbol reference" do
      source = <<~MIXAL
        BASE  EQU 1000
        LIMIT EQU BASE+100
        START LDA LIMIT
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("BASE")).to eq(1000)
      expect(assembler.symbol_table.lookup("LIMIT")).to eq(1100)
      expect(assembler.symbol_table.lookup("START")).to eq(0)
    end

    it "handles multiple ORIG directives" do
      source = <<~MIXAL
              ORIG 100
        L1    LDA 0
              ORIG 200
        L2    STA 0
              ORIG 150
        L3    HLT
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("L1")).to eq(100)
      expect(assembler.symbol_table.lookup("L2")).to eq(200)
      expect(assembler.symbol_table.lookup("L3")).to eq(150)
    end

    it "tracks instruction locations correctly" do
      source = <<~MIXAL
        START LDA VALUE
              STA RESULT
              ADD VALUE
              HLT
        VALUE CON 100
        RESULT CON 0
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("START")).to eq(0)
      expect(assembler.symbol_table.lookup("VALUE")).to eq(4)
      expect(assembler.symbol_table.lookup("RESULT")).to eq(5)
    end

    it "handles labels on pseudo-ops" do
      source = <<~MIXAL
        DATA  CON 42
        TEXT  ALF HELLO
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("DATA")).to eq(0)
      expect(assembler.symbol_table.lookup("TEXT")).to eq(1)
    end
  end

  describe "complex programs" do
    it "assembles factorial program" do
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

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("START")).to eq(0)
      expect(assembler.symbol_table.lookup("LOOP")).to eq(3)
      expect(assembler.symbol_table.lookup("N")).to eq(10)
    end

    it "assembles program with all directive types" do
      source = <<~MIXAL
              ORIG 1000
        SIZE  EQU 100
        BASE  CON 0
        START LDA BASE
              STA BASE+SIZE
              HLT
        MSG   ALF HELLO
              END START
      MIXAL

      assembler.assemble(source)

      expect(assembler.symbol_table.lookup("SIZE")).to eq(100)
      expect(assembler.symbol_table.lookup("BASE")).to eq(1000)
      expect(assembler.symbol_table.lookup("START")).to eq(1001)
      expect(assembler.symbol_table.lookup("MSG")).to eq(1004)
    end

    it "handles forward references correctly" do
      source = <<~MIXAL
        START JMP DONE
              LDA VALUE
        DONE  HLT
        VALUE CON 42
      MIXAL

      assembler.assemble(source)

      # Symbols should be defined even if referenced before definition
      expect(assembler.symbol_table.lookup("START")).to eq(0)
      expect(assembler.symbol_table.lookup("DONE")).to eq(2)
      expect(assembler.symbol_table.lookup("VALUE")).to eq(3)
    end
  end

  describe "instruction tracking" do
    it "stores instructions with locations" do
      source = <<~MIXAL
        START LDA 1000
              STA 2000
              HLT
      MIXAL

      assembler.assemble(source)

      expect(assembler.instructions.length).to eq(3)
      expect(assembler.instructions[0][:location]).to eq(0)
      expect(assembler.instructions[1][:location]).to eq(1)
      expect(assembler.instructions[2][:location]).to eq(2)
    end

    it "tracks instructions after ORIG" do
      source = <<~MIXAL
              ORIG 500
        L1    LDA 0
        L2    STA 0
      MIXAL

      assembler.assemble(source)

      expect(assembler.instructions[0][:location]).to eq(500)
      expect(assembler.instructions[1][:location]).to eq(501)
    end
  end

  describe "error handling" do
    it "raises error for EQU without label" do
      source = "EQU 100"

      expect {
        assembler.assemble(source)
      }.to raise_error(Quackers::Mixal::Assembler::Error, /EQU requires a label/)
    end

    it "raises error for duplicate label" do
      source = <<~MIXAL
        LABEL LDA 0
        LABEL STA 0
      MIXAL

      expect {
        assembler.assemble(source)
      }.to raise_error(Quackers::Mixal::SymbolTable::Error, /already defined/)
    end
  end
end
