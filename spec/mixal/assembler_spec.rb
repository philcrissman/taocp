# frozen_string_literal: true

RSpec.describe Taocp::Mixal::Assembler do
  let(:assembler) { Taocp::Mixal::Assembler.new }

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
      }.to raise_error(Taocp::Mixal::Assembler::Error, /EQU requires a label/)
    end

    it "raises error for duplicate label" do
      source = <<~MIXAL
        LABEL LDA 0
        LABEL STA 0
      MIXAL

      expect {
        assembler.assemble(source)
      }.to raise_error(Taocp::Mixal::SymbolTable::Error, /already defined/)
    end
  end

  describe "second pass - code generation" do
    it "generates machine code for simple program" do
      source = <<~MIXAL
        START LDA VALUE
              HLT
        VALUE CON 100
      MIXAL

      assembler.assemble(source)

      # Check memory contains generated code
      expect(assembler.memory[0]).to be_a(Taocp::Mix::Word)
      expect(assembler.memory[1]).to be_a(Taocp::Mix::Word)
      expect(assembler.memory[2]).to be_a(Taocp::Mix::Word)

      # VALUE should be 100
      expect(assembler.memory[2].to_i).to eq(100)
    end

    it "generates correct LDA instruction" do
      source = "LDA 1000"
      assembler.assemble(source)

      word = assembler.memory[0]
      inst = Taocp::Mix::Instruction.from_word(word)

      expect(inst.opcode).to eq(Taocp::Mix::Instruction::LDA)
      expect(inst.address).to eq(1000)
      expect(inst.field).to eq(5)  # Default field for LDA
    end

    it "generates instruction with index" do
      source = "LDA 1000,1"
      assembler.assemble(source)

      word = assembler.memory[0]
      inst = Taocp::Mix::Instruction.from_word(word)

      expect(inst.address).to eq(1000)
      expect(inst.index).to eq(1)
    end

    it "generates instruction with field specification" do
      source = "LDA 1000(1:3)"
      assembler.assemble(source)

      word = assembler.memory[0]
      inst = Taocp::Mix::Instruction.from_word(word)

      # Field 1:3 encodes as 8*1 + 3 = 11
      expect(inst.field).to eq(11)
    end

    it "resolves symbolic addresses" do
      source = <<~MIXAL
        START JMP LOOP
        LOOP  HLT
      MIXAL

      assembler.assemble(source)

      word = assembler.memory[0]
      inst = Taocp::Mix::Instruction.from_word(word)

      # JMP should jump to address 1 (where LOOP is)
      expect(inst.address).to eq(1)
    end

    it "handles CON directive" do
      source = "VALUE CON 12345"
      assembler.assemble(source)

      expect(assembler.memory[0].to_i).to eq(12345)
    end

    it "handles ALF directive" do
      source = 'TEXT ALF HELLO'
      assembler.assemble(source)

      word = assembler.memory[0]
      # Check that bytes contain MIX character codes
      expect(word.bytes).to be_an(Array)
      expect(word.bytes.length).to eq(5)
    end

    it "handles negative addresses" do
      source = "LDA -100"
      assembler.assemble(source)

      word = assembler.memory[0]
      inst = Taocp::Mix::Instruction.from_word(word)

      expect(inst.sign).to eq(-1)
      expect(inst.address).to eq(100)
    end

    it "sets start address from END directive" do
      source = <<~MIXAL
        START LDA 0
              HLT
              END START
      MIXAL

      assembler.assemble(source)

      expect(assembler.start_address).to eq(0)
    end
  end

  describe "complete program assembly" do
    it "assembles and can run simple program" do
      source = <<~MIXAL
        * Load value and store it
        START LDA VALUE
              STA RESULT
              HLT
        VALUE CON 42
        RESULT CON 0
              END START
      MIXAL

      assembler.assemble(source)

      # Create machine and load the program
      machine = Taocp::Mix::Machine.new

      # Copy assembled code to machine memory
      (0...10).each do |addr|
        machine.memory[addr] = assembler.memory[addr]
      end

      # Run the program
      machine.run

      # Check result
      result_addr = assembler.symbol_table.lookup("RESULT")
      expect(machine.memory[result_addr].to_i).to eq(42)
    end
  end

  describe "literal pool management" do
    it "collects literals in a pool at end of program" do
      source = <<~MIXAL
        START LDA =100=
              STA =200=
              HLT
      MIXAL

      assembler.assemble(source)

      # Literals should be at locations 3 and 4 (after the 3 instructions)
      expect(assembler.memory[3].to_i).to eq(100)
      expect(assembler.memory[4].to_i).to eq(200)

      # First instruction should reference location 3
      inst = Taocp::Mix::Instruction.from_word(assembler.memory[0])
      expect(inst.address).to eq(3)
    end

    it "reuses same literal" do
      source = <<~MIXAL
        L1 LDA =42=
        L2 ADD =42=
           HLT
      MIXAL

      assembler.assemble(source)

      # Should only have one literal in the pool (location 3)
      expect(assembler.memory[3].to_i).to eq(42)

      # Both instructions should reference the same location
      inst1 = Taocp::Mix::Instruction.from_word(assembler.memory[0])
      inst2 = Taocp::Mix::Instruction.from_word(assembler.memory[1])
      expect(inst1.address).to eq(3)
      expect(inst2.address).to eq(3)
    end
  end
end

