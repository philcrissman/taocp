# frozen_string_literal: true

require "test_helper"

class Taocp::Mixal::AssemblerTest < Minitest::Test
  def setup
    @assembler = Taocp::Mixal::Assembler.new
  end

  # First pass - symbol table construction

  def test_builds_symbol_table_for_simple_program
    source = <<~MIXAL
      START LDA VALUE
            HLT
      VALUE CON 100
    MIXAL

    @assembler.assemble(source)

    assert_equal 0, @assembler.symbol_table.lookup("START")
    assert_equal 2, @assembler.symbol_table.lookup("VALUE")
  end

  def test_handles_orig_directive
    source = <<~MIXAL
            ORIG 1000
      START LDA VALUE
      VALUE CON 100
    MIXAL

    @assembler.assemble(source)

    assert_equal 1000, @assembler.symbol_table.lookup("START")
    assert_equal 1001, @assembler.symbol_table.lookup("VALUE")
  end

  def test_handles_equ_directive
    source = <<~MIXAL
      SIZE  EQU 100
      START LDA SIZE
            HLT
    MIXAL

    @assembler.assemble(source)

    assert_equal 100, @assembler.symbol_table.lookup("SIZE")
    assert_equal 0, @assembler.symbol_table.lookup("START")
  end

  def test_handles_equ_with_symbol_reference
    source = <<~MIXAL
      BASE  EQU 1000
      LIMIT EQU BASE+100
      START LDA LIMIT
    MIXAL

    @assembler.assemble(source)

    assert_equal 1000, @assembler.symbol_table.lookup("BASE")
    assert_equal 1100, @assembler.symbol_table.lookup("LIMIT")
    assert_equal 0, @assembler.symbol_table.lookup("START")
  end

  def test_handles_multiple_orig_directives
    source = <<~MIXAL
            ORIG 100
      L1    LDA 0
            ORIG 200
      L2    STA 0
            ORIG 150
      L3    HLT
    MIXAL

    @assembler.assemble(source)

    assert_equal 100, @assembler.symbol_table.lookup("L1")
    assert_equal 200, @assembler.symbol_table.lookup("L2")
    assert_equal 150, @assembler.symbol_table.lookup("L3")
  end

  def test_tracks_instruction_locations_correctly
    source = <<~MIXAL
      START LDA VALUE
            STA RESULT
            ADD VALUE
            HLT
      VALUE CON 100
      RESULT CON 0
    MIXAL

    @assembler.assemble(source)

    assert_equal 0, @assembler.symbol_table.lookup("START")
    assert_equal 4, @assembler.symbol_table.lookup("VALUE")
    assert_equal 5, @assembler.symbol_table.lookup("RESULT")
  end

  def test_handles_labels_on_pseudo_ops
    source = <<~MIXAL
      DATA  CON 42
      TEXT  ALF HELLO
    MIXAL

    @assembler.assemble(source)

    assert_equal 0, @assembler.symbol_table.lookup("DATA")
    assert_equal 1, @assembler.symbol_table.lookup("TEXT")
  end

  # Complex programs

  def test_assembles_factorial_program
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

    @assembler.assemble(source)

    assert_equal 0, @assembler.symbol_table.lookup("START")
    assert_equal 3, @assembler.symbol_table.lookup("LOOP")
    assert_equal 10, @assembler.symbol_table.lookup("N")
  end

  def test_assembles_program_with_all_directive_types
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

    @assembler.assemble(source)

    assert_equal 100, @assembler.symbol_table.lookup("SIZE")
    assert_equal 1000, @assembler.symbol_table.lookup("BASE")
    assert_equal 1001, @assembler.symbol_table.lookup("START")
    assert_equal 1004, @assembler.symbol_table.lookup("MSG")
  end

  def test_handles_forward_references_correctly
    source = <<~MIXAL
      START JMP DONE
            LDA VALUE
      DONE  HLT
      VALUE CON 42
    MIXAL

    @assembler.assemble(source)

    # Symbols should be defined even if referenced before definition
    assert_equal 0, @assembler.symbol_table.lookup("START")
    assert_equal 2, @assembler.symbol_table.lookup("DONE")
    assert_equal 3, @assembler.symbol_table.lookup("VALUE")
  end

  # Instruction tracking

  def test_stores_instructions_with_locations
    source = <<~MIXAL
      START LDA 1000
            STA 2000
            HLT
    MIXAL

    @assembler.assemble(source)

    assert_equal 3, @assembler.instructions.length
    assert_equal 0, @assembler.instructions[0][:location]
    assert_equal 1, @assembler.instructions[1][:location]
    assert_equal 2, @assembler.instructions[2][:location]
  end

  def test_tracks_instructions_after_orig
    source = <<~MIXAL
            ORIG 500
      L1    LDA 0
      L2    STA 0
    MIXAL

    @assembler.assemble(source)

    assert_equal 500, @assembler.instructions[0][:location]
    assert_equal 501, @assembler.instructions[1][:location]
  end

  # Error handling

  def test_raises_error_for_equ_without_label
    source = "EQU 100"

    error = assert_raises(Taocp::Mixal::Assembler::Error) do
      @assembler.assemble(source)
    end

    assert_match(/EQU requires a label/, error.message)
  end

  def test_raises_error_for_duplicate_label
    source = <<~MIXAL
      LABEL LDA 0
      LABEL STA 0
    MIXAL

    error = assert_raises(Taocp::Mixal::SymbolTable::Error) do
      @assembler.assemble(source)
    end

    assert_match(/already defined/, error.message)
  end

  # Second pass - code generation

  def test_generates_machine_code_for_simple_program
    source = <<~MIXAL
      START LDA VALUE
            HLT
      VALUE CON 100
    MIXAL

    @assembler.assemble(source)

    # Check memory contains generated code
    assert_kind_of Taocp::Mix::Word, @assembler.memory[0]
    assert_kind_of Taocp::Mix::Word, @assembler.memory[1]
    assert_kind_of Taocp::Mix::Word, @assembler.memory[2]

    # VALUE should be 100
    assert_equal 100, @assembler.memory[2].to_i
  end

  def test_generates_correct_lda_instruction
    source = "LDA 1000"
    @assembler.assemble(source)

    word = @assembler.memory[0]
    inst = Taocp::Mix::Instruction.from_word(word)

    assert_equal Taocp::Mix::Instruction::LDA, inst.opcode
    assert_equal 1000, inst.address
    assert_equal 5, inst.field  # Default field for LDA
  end

  def test_generates_instruction_with_index
    source = "LDA 1000,1"
    @assembler.assemble(source)

    word = @assembler.memory[0]
    inst = Taocp::Mix::Instruction.from_word(word)

    assert_equal 1000, inst.address
    assert_equal 1, inst.index
  end

  def test_generates_instruction_with_field_specification
    source = "LDA 1000(1:3)"
    @assembler.assemble(source)

    word = @assembler.memory[0]
    inst = Taocp::Mix::Instruction.from_word(word)

    # Field 1:3 encodes as 8*1 + 3 = 11
    assert_equal 11, inst.field
  end

  def test_resolves_symbolic_addresses
    source = <<~MIXAL
      START JMP LOOP
      LOOP  HLT
    MIXAL

    @assembler.assemble(source)

    word = @assembler.memory[0]
    inst = Taocp::Mix::Instruction.from_word(word)

    # JMP should jump to address 1 (where LOOP is)
    assert_equal 1, inst.address
  end

  def test_handles_con_directive
    source = "VALUE CON 12345"
    @assembler.assemble(source)

    assert_equal 12345, @assembler.memory[0].to_i
  end

  def test_handles_alf_directive
    source = 'TEXT ALF HELLO'
    @assembler.assemble(source)

    word = @assembler.memory[0]
    # Check that bytes contain MIX character codes
    assert_kind_of Array, word.bytes
    assert_equal 5, word.bytes.length
  end

  def test_handles_negative_addresses
    source = "LDA -100"
    @assembler.assemble(source)

    word = @assembler.memory[0]
    inst = Taocp::Mix::Instruction.from_word(word)

    assert_equal(-1, inst.sign)
    assert_equal 100, inst.address
  end

  def test_sets_start_address_from_end_directive
    source = <<~MIXAL
      START LDA 0
            HLT
            END START
    MIXAL

    @assembler.assemble(source)

    assert_equal 0, @assembler.start_address
  end

  # Complete program assembly

  def test_assembles_and_can_run_simple_program
    source = <<~MIXAL
      * Load value and store it
      START LDA VALUE
            STA RESULT
            HLT
      VALUE CON 42
      RESULT CON 0
            END START
    MIXAL

    @assembler.assemble(source)

    # Create machine and load the program
    machine = Taocp::Mix::Machine.new

    # Copy assembled code to machine memory
    (0...10).each do |addr|
      machine.memory[addr] = @assembler.memory[addr]
    end

    # Run the program
    machine.run

    # Check result
    result_addr = @assembler.symbol_table.lookup("RESULT")
    assert_equal 42, machine.memory[result_addr].to_i
  end

  # Literal pool management

  def test_collects_literals_in_a_pool_at_end_of_program
    source = <<~MIXAL
      START LDA =100=
            STA =200=
            HLT
    MIXAL

    @assembler.assemble(source)

    # Literals should be at locations 3 and 4 (after the 3 instructions)
    assert_equal 100, @assembler.memory[3].to_i
    assert_equal 200, @assembler.memory[4].to_i

    # First instruction should reference location 3
    inst = Taocp::Mix::Instruction.from_word(@assembler.memory[0])
    assert_equal 3, inst.address
  end

  def test_reuses_same_literal
    source = <<~MIXAL
      L1 LDA =42=
      L2 ADD =42=
         HLT
    MIXAL

    @assembler.assemble(source)

    # Should only have one literal in the pool (location 3)
    assert_equal 42, @assembler.memory[3].to_i

    # Both instructions should reference the same location
    inst1 = Taocp::Mix::Instruction.from_word(@assembler.memory[0])
    inst2 = Taocp::Mix::Instruction.from_word(@assembler.memory[1])
    assert_equal 3, inst1.address
    assert_equal 3, inst2.address
  end
end
