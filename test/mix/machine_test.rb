# frozen_string_literal: true

require "test_helper"

class MixMachineTest < Minitest::Test
  def setup
    @machine = Taocp::Mix::Machine.new
  end

  # Initialization tests
  def test_creates_a_new_machine_with_initialized_state
    assert_instance_of Taocp::Mix::Memory, @machine.memory
    assert_instance_of Taocp::Mix::Registers, @machine.registers
    assert_equal 0, @machine.pc
    assert_equal false, @machine.halted
  end

  def test_initializes_memory_with_zero_words
    assert_equal 0, @machine.memory[0].to_i
    assert_equal 0, @machine.memory[100].to_i
    assert_equal 0, @machine.memory[3999].to_i
  end

  def test_initializes_all_registers_to_zero
    assert_equal 0, @machine.registers.a.to_i
    assert_equal 0, @machine.registers.x.to_i
    (1..6).each do |i|
      assert_equal 0, @machine.registers.get_index(i).to_i
    end
    assert_equal 0, @machine.registers.j
  end

  # Reset tests
  def test_resets_machine_to_initial_state
    # Modify machine state
    @machine.memory[100] = Taocp::Mix::Word.from_i(42)
    @machine.registers.a = Taocp::Mix::Word.from_i(99)
    @machine.instance_variable_set(:@pc, 50)
    @machine.halted = true

    # Reset
    @machine.reset

    # Verify reset
    assert_equal 0, @machine.memory[100].to_i
    assert_equal 0, @machine.registers.a.to_i
    assert_equal 0, @machine.pc
    assert_equal false, @machine.halted
  end

  # Memory access tests
  def test_allows_reading_and_writing_memory
    word = Taocp::Mix::Word.from_i(12345)
    @machine.memory[500] = word

    assert_equal 12345, @machine.memory[500].to_i
  end

  def test_maintains_separate_memory_locations
    @machine.memory[0] = Taocp::Mix::Word.from_i(1)
    @machine.memory[1] = Taocp::Mix::Word.from_i(2)
    @machine.memory[2] = Taocp::Mix::Word.from_i(3)

    assert_equal 1, @machine.memory[0].to_i
    assert_equal 2, @machine.memory[1].to_i
    assert_equal 3, @machine.memory[2].to_i
  end

  # Register access tests
  def test_allows_setting_and_getting_register_a
    word = Taocp::Mix::Word.from_i(100)
    @machine.registers.a = word
    assert_equal 100, @machine.registers.a.to_i
  end

  def test_allows_setting_and_getting_register_x
    word = Taocp::Mix::Word.from_i(200)
    @machine.registers.x = word
    assert_equal 200, @machine.registers.x.to_i
  end

  def test_allows_setting_and_getting_index_registers
    (1..6).each do |i|
      @machine.registers.set_index_i(i, i * 10)
      assert_equal i * 10, @machine.registers.get_index_i(i)
    end
  end

  def test_sets_comparison_flag
    @machine.registers.comparison_flag = :greater
    assert_equal :greater, @machine.registers.comparison_flag
  end

  def test_sets_overflow_flag
    @machine.registers.overflow = true
    assert_equal true, @machine.registers.overflow
  end

  # HLT instruction tests
  def test_hlt_instruction_halts_the_machine
    # Create HLT instruction at memory[0]
    hlt_inst = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::HLT, field: 2)
    @machine.memory[0] = hlt_inst.to_word

    @machine.step

    assert_equal true, @machine.halted
    assert_equal 1, @machine.pc
  end

  # NOP instruction tests
  def test_nop_instruction_does_nothing_but_advances_pc
    nop_inst = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::NOP)
    @machine.memory[0] = nop_inst.to_word

    @machine.step

    assert_equal 1, @machine.pc
    assert_equal false, @machine.halted
  end

  # step tests
  def test_step_fetches_decodes_and_executes_one_instruction
    # Put two NOPs and a HLT
    nop = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::NOP).to_word
    hlt = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::HLT, field: 2).to_word

    @machine.memory[0] = nop
    @machine.memory[1] = nop
    @machine.memory[2] = hlt

    @machine.step
    assert_equal 1, @machine.pc
    assert_equal false, @machine.halted

    @machine.step
    assert_equal 2, @machine.pc
    assert_equal false, @machine.halted

    @machine.step
    assert_equal 3, @machine.pc
    assert_equal true, @machine.halted
  end

  def test_step_does_nothing_if_already_halted
    @machine.halted = true
    @machine.pc = 5

    @machine.step

    assert_equal 5, @machine.pc  # Unchanged
  end

  # run tests
  def test_run_runs_until_hlt
    # Create a simple program: 3 NOPs then HLT
    nop = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::NOP).to_word
    hlt = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::HLT, field: 2).to_word

    @machine.memory[0] = nop
    @machine.memory[1] = nop
    @machine.memory[2] = nop
    @machine.memory[3] = hlt

    count = @machine.run

    assert_equal true, @machine.halted
    assert_equal 4, @machine.pc
    assert_equal 4, count
  end

  def test_run_stops_after_max_instructions_to_prevent_infinite_loops
    # Create a program that runs past the limit
    # We'll fill memory with enough NOPs that it would exceed MAX_INSTRUCTIONS
    nop = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::NOP).to_word
    # Fill first 1000 locations with NOPs (more than enough to hit limit)
    (0...1000).each { |i| @machine.memory[i] = nop }

    # Override MAX_INSTRUCTIONS temporarily for faster test
    original_max = Taocp::Mix::Machine::MAX_INSTRUCTIONS
    Taocp::Mix::Machine.const_set(:MAX_INSTRUCTIONS, 500)

    # Should raise after 500 instructions
    assert_raises(Taocp::Mix::Error, /Instruction limit exceeded/) do
      @machine.run
    end

    # Restore original
    Taocp::Mix::Machine.const_set(:MAX_INSTRUCTIONS, original_max)
  end

  def test_run_returns_instruction_count
    nop = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::NOP).to_word
    hlt = Taocp::Mix::Instruction.new(opcode: Taocp::Mix::Instruction::HLT, field: 2).to_word

    @machine.memory[0] = nop
    @machine.memory[1] = nop
    @machine.memory[2] = hlt

    count = @machine.run
    assert_equal 3, count
    assert_equal 3, @machine.instruction_count
  end
end

class MixRegistersTest < Minitest::Test
  def setup
    @registers = Taocp::Mix::Registers.new
  end

  # get_index and set_index tests
  def test_gets_and_sets_index_register_by_number
    word = Taocp::Mix::Word.from_i(42)
    @registers.set_index(3, word)
    assert_equal 42, @registers.get_index(3).to_i
  end

  def test_raises_error_for_invalid_index_number
    assert_raises(Taocp::Mix::Error) { @registers.get_index(0) }
    assert_raises(Taocp::Mix::Error) { @registers.get_index(7) }
    assert_raises(Taocp::Mix::Error) { @registers.set_index(0, Taocp::Mix::Word.new) }
  end

  # set_index_i and get_index_i tests
  def test_sets_index_register_from_integer
    @registers.set_index_i(1, 100)
    assert_equal 100, @registers.get_index_i(1)
  end

  def test_handles_negative_values
    @registers.set_index_i(2, -50)
    assert_equal(-50, @registers.get_index_i(2))
  end

  def test_raises_error_for_values_exceeding_2_byte_capacity
    assert_raises(ArgumentError, /out of range/) { @registers.set_index_i(1, 5000) }
    assert_raises(ArgumentError, /out of range/) { @registers.set_index_i(1, -5000) }
  end

  def test_handles_maximum_valid_values
    @registers.set_index_i(1, 4095)
    assert_equal 4095, @registers.get_index_i(1)

    @registers.set_index_i(2, -4095)
    assert_equal(-4095, @registers.get_index_i(2))
  end
end

class MixMemoryTest < Minitest::Test
  def setup
    @memory = Taocp::Mix::Memory.new
  end

  # Initialization tests
  def test_creates_4000_words_of_memory
    assert_instance_of Taocp::Mix::Word, @memory[0]
    assert_instance_of Taocp::Mix::Word, @memory[3999]
  end

  def test_initializes_all_memory_to_zero
    assert_equal 0, @memory[0].to_i
    assert_equal 0, @memory[1000].to_i
    assert_equal 0, @memory[3999].to_i
  end

  # Bounds checking tests
  def test_raises_error_for_negative_address
    assert_raises(Taocp::Mix::Error, /Invalid memory address/) { @memory[-1] }
  end

  def test_raises_error_for_address_gte_4000
    assert_raises(Taocp::Mix::Error, /Invalid memory address/) { @memory[4000] }
    assert_raises(Taocp::Mix::Error, /Invalid memory address/) { @memory[5000] }
  end

  def test_allows_valid_addresses_0_to_3999
    assert @memory[0]
    assert @memory[3999]
  end

  # Storage and retrieval tests
  def test_stores_and_retrieves_words_correctly
    word = Taocp::Mix::Word.from_i(12345)
    @memory[100] = word
    assert_equal 12345, @memory[100].to_i
  end

  def test_maintains_independent_storage_locations
    @memory[0] = Taocp::Mix::Word.from_i(1)
    @memory[1] = Taocp::Mix::Word.from_i(2)
    assert_equal 1, @memory[0].to_i
    assert_equal 2, @memory[1].to_i
  end
end
