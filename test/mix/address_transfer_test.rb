# frozen_string_literal: true

require "test_helper"

class MixAddressTransferTest < Minitest::Test
  def setup
    @machine = Taocp::Mix::Machine.new
    @inst_class = Taocp::Mix::Instruction
    @word_class = Taocp::Mix::Word
  end

  # ENT - Enter register tests
  def test_enta_sets_a_register_to_immediate_value
    # ENTA 100 (field=0 for ENT)
    inst = @inst_class.new(address: 100, field: 0, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 100, @machine.registers.a.to_i
  end

  def test_entx_sets_x_register
    inst = @inst_class.new(address: 50, field: 0, opcode: 55)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 50, @machine.registers.x.to_i
  end

  def test_ent1_ent6_set_index_registers
    (1..6).each do |i|
      @machine.reset
      # ENTi with value = i * 10
      inst = @inst_class.new(address: i * 10, field: 0, opcode: 48 + i)
      @machine.memory[0] = inst.to_word

      @machine.step

      assert_equal i * 10, @machine.registers.get_index_i(i)
    end
  end

  def test_ent_can_use_index_register_for_address_calculation
    @machine.registers.set_index_i(1, 50)
    # ENTA 100,1 -> enters 100 + I1 = 150
    inst = @inst_class.new(address: 100, index: 1, field: 0, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 150, @machine.registers.a.to_i
  end

  # ENN - Enter negative tests
  def test_enna_sets_a_to_negative_of_immediate_value
    inst = @inst_class.new(address: 75, field: 1, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal(-75, @machine.registers.a.to_i)
  end

  def test_ennx_sets_x_to_negative
    inst = @inst_class.new(address: 25, field: 1, opcode: 55)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal(-25, @machine.registers.x.to_i)
  end

  def test_enn1_sets_index_register_to_negative
    inst = @inst_class.new(address: 10, field: 1, opcode: 49)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal(-10, @machine.registers.get_index_i(1))
  end

  # INC - Increment register tests
  def test_inca_increments_a_register
    @machine.registers.a = @word_class.from_i(100)

    # INCA 25
    inst = @inst_class.new(address: 25, field: 2, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 125, @machine.registers.a.to_i
  end

  def test_incx_increments_x_register
    @machine.registers.x = @word_class.from_i(50)

    inst = @inst_class.new(address: 10, field: 2, opcode: 55)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 60, @machine.registers.x.to_i
  end

  def test_inc1_increments_index_register
    @machine.registers.set_index_i(1, 100)

    inst = @inst_class.new(address: 5, field: 2, opcode: 49)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 105, @machine.registers.get_index_i(1)
  end

  def test_inc_by_large_value
    @machine.registers.a = @word_class.from_i(100)

    # INCA 500
    inst = @inst_class.new(address: 500, field: 2, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 600, @machine.registers.a.to_i
  end

  def test_inc_sets_overflow_on_overflow
    @machine.registers.a = @word_class.from_i(@word_class::MAX_VALUE)

    inst = @inst_class.new(address: 1, field: 2, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal true, @machine.registers.overflow
  end

  # DEC - Decrement register tests
  def test_deca_decrements_a_register
    @machine.registers.a = @word_class.from_i(100)

    # DECA 30
    inst = @inst_class.new(address: 30, field: 3, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 70, @machine.registers.a.to_i
  end

  def test_decx_decrements_x_register
    @machine.registers.x = @word_class.from_i(50)

    inst = @inst_class.new(address: 10, field: 3, opcode: 55)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 40, @machine.registers.x.to_i
  end

  def test_dec1_decrements_index_register
    @machine.registers.set_index_i(1, 100)

    inst = @inst_class.new(address: 25, field: 3, opcode: 49)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 75, @machine.registers.get_index_i(1)
  end

  def test_dec_can_produce_negative_results
    @machine.registers.a = @word_class.from_i(10)

    # DECA 50
    inst = @inst_class.new(address: 50, field: 3, opcode: 48)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal(-40, @machine.registers.a.to_i)
  end

  # Array indexing patterns tests
  def test_uses_index_register_to_access_array_elements
    # Set up an array in memory at locations 100-104
    (0..4).each do |i|
      @machine.memory[100 + i] = @word_class.from_i((i + 1) * 10)
    end

    # Program: Sum array elements using index register
    # Memory[200] = sum (result)
    # I1 = array index (0 to 4)

    @machine.memory[200] = @word_class.from_i(0)  # sum = 0

    # ENT1 0 - Initialize index to 0
    @machine.memory[0] = @inst_class.new(address: 0, field: 0, opcode: 49).to_word

    # Loop start (address 1)
    # LDA 200 - Load current sum
    @machine.memory[1] = @inst_class.new(address: 200, field: 5, opcode: @inst_class::LDA).to_word

    # ADD 100,1 - Add array[i] (100 + I1)
    @machine.memory[2] = @inst_class.new(address: 100, index: 1, field: 5, opcode: @inst_class::ADD).to_word

    # STA 200 - Store sum
    @machine.memory[3] = @inst_class.new(address: 200, field: 5, opcode: @inst_class::STA).to_word

    # INC1 1 - Increment index
    @machine.memory[4] = @inst_class.new(address: 1, field: 2, opcode: 49).to_word

    # CMP1 5 - Compare index with 5
    @machine.memory[5] = @inst_class.new(address: 205, field: 5, opcode: @inst_class::CMP1).to_word
    @machine.memory[205] = @word_class.from_i(5)

    # JL 1 - Jump to loop start if less
    @machine.memory[6] = @inst_class.new(address: 1, field: 4, opcode: @inst_class::JMP).to_word

    # HLT
    @machine.memory[7] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    @machine.run

    # Sum should be 10 + 20 + 30 + 40 + 50 = 150
    assert_equal 150, @machine.memory[200].to_i
    assert_equal true, @machine.halted
  end

  def test_finds_maximum_element_in_array_using_index_register
    # Array at 100-104: 15, 42, 8, 99, 23
    @machine.memory[100] = @word_class.from_i(15)
    @machine.memory[101] = @word_class.from_i(42)
    @machine.memory[102] = @word_class.from_i(8)
    @machine.memory[103] = @word_class.from_i(99)
    @machine.memory[104] = @word_class.from_i(23)

    # Result at 200
    @machine.memory[200] = @word_class.from_i(0)  # max

    # ENT1 0 - index = 0
    @machine.memory[0] = @inst_class.new(address: 0, field: 0, opcode: 49).to_word

    # LDA 100 - Load first element as initial max
    @machine.memory[1] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::LDA).to_word

    # STA 200 - Store as max
    @machine.memory[2] = @inst_class.new(address: 200, field: 5, opcode: @inst_class::STA).to_word

    # Loop: check rest of array
    # INC1 1 - Move to next element
    @machine.memory[3] = @inst_class.new(address: 1, field: 2, opcode: 49).to_word

    # CMPA 100,1 - Compare max with current element
    @machine.memory[4] = @inst_class.new(address: 100, index: 1, field: 5, opcode: @inst_class::CMPA).to_word

    # JGE 7 - If max >= current, skip update
    @machine.memory[5] = @inst_class.new(address: 7, field: 7, opcode: @inst_class::JMP).to_word

    # LDA 100,1 - Load new max
    @machine.memory[6] = @inst_class.new(address: 100, index: 1, field: 5, opcode: @inst_class::LDA).to_word

    # STA 200 - Store new max (address 7)
    @machine.memory[7] = @inst_class.new(address: 200, field: 5, opcode: @inst_class::STA).to_word

    # CMP1 constant 4 - Are we done?
    @machine.memory[8] = @inst_class.new(address: 210, field: 5, opcode: @inst_class::CMP1).to_word
    @machine.memory[210] = @word_class.from_i(4)

    # JL 3 - Loop if index < 4
    @machine.memory[9] = @inst_class.new(address: 3, field: 4, opcode: @inst_class::JMP).to_word

    # HLT
    @machine.memory[10] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    @machine.run

    assert_equal 99, @machine.memory[200].to_i  # Maximum is 99
    assert_equal true, @machine.halted
  end

  def test_copies_array_using_two_index_registers
    # Source array at 100-102
    @machine.memory[100] = @word_class.from_i(10)
    @machine.memory[101] = @word_class.from_i(20)
    @machine.memory[102] = @word_class.from_i(30)

    # ENT1 0 - source index
    @machine.memory[0] = @inst_class.new(address: 0, field: 0, opcode: 49).to_word

    # ENT2 0 - dest index
    @machine.memory[1] = @inst_class.new(address: 0, field: 0, opcode: 50).to_word

    # Loop (address 2)
    # LDA 100,1 - Load from source
    @machine.memory[2] = @inst_class.new(address: 100, index: 1, field: 5, opcode: @inst_class::LDA).to_word

    # STA 200,2 - Store to dest (200 + I2)
    @machine.memory[3] = @inst_class.new(address: 200, index: 2, field: 5, opcode: @inst_class::STA).to_word

    # INC1 1
    @machine.memory[4] = @inst_class.new(address: 1, field: 2, opcode: 49).to_word

    # INC2 1
    @machine.memory[5] = @inst_class.new(address: 1, field: 2, opcode: 50).to_word

    # CMP1 3
    @machine.memory[6] = @inst_class.new(address: 300, field: 5, opcode: @inst_class::CMP1).to_word
    @machine.memory[300] = @word_class.from_i(3)

    # JL 2
    @machine.memory[7] = @inst_class.new(address: 2, field: 4, opcode: @inst_class::JMP).to_word

    # HLT
    @machine.memory[8] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    @machine.run

    # Check copied array
    assert_equal 10, @machine.memory[200].to_i
    assert_equal 20, @machine.memory[201].to_i
    assert_equal 30, @machine.memory[202].to_i
  end

  # Loop counter patterns tests
  def test_uses_dec_for_counting_down
    # Traditional countdown loop using DEC

    # ENT1 10 - counter = 10
    @machine.memory[0] = @inst_class.new(address: 10, field: 0, opcode: 49).to_word

    # Loop (address 1)
    # DEC1 1 - Decrement counter
    @machine.memory[1] = @inst_class.new(address: 1, field: 3, opcode: 49).to_word

    # J1P 1 - Jump if I1 > 0
    # For this we need to compare and jump
    # CMP1 0
    @machine.memory[2] = @inst_class.new(address: 400, field: 5, opcode: @inst_class::CMP1).to_word
    @machine.memory[400] = @word_class.from_i(0)

    # JG 1
    @machine.memory[3] = @inst_class.new(address: 1, field: 6, opcode: @inst_class::JMP).to_word

    # HLT
    @machine.memory[4] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    @machine.run

    assert_equal 0, @machine.registers.get_index_i(1)
    assert_equal true, @machine.halted
  end
end
