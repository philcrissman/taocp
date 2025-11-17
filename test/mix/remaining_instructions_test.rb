# frozen_string_literal: true

require "test_helper"

class MixRemainingInstructionsTest < Minitest::Test
  def setup
    @machine = Taocp::Mix::Machine.new
    @inst_class = Taocp::Mix::Instruction
    @word_class = Taocp::Mix::Word
  end

  # Shift instructions
  # SLA - Shift Left A
  def test_sla_shifts_a_left_by_one_position
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

    # SLA 1 (shift left by 1)
    inst = @inst_class.new(address: 1, field: 0, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Result: [2, 3, 4, 5, 0]
    assert_equal [2, 3, 4, 5, 0], @machine.registers.a.bytes
  end

  def test_sla_shifts_a_left_by_two_positions
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

    inst = @inst_class.new(address: 2, field: 0, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal [3, 4, 5, 0, 0], @machine.registers.a.bytes
  end

  def test_sla_preserves_sign_during_shift
    @machine.registers.a = @word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])

    inst = @inst_class.new(address: 1, field: 0, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal -1, @machine.registers.a.sign
    assert_equal [2, 3, 4, 5, 0], @machine.registers.a.bytes
  end

  def test_sla_handles_shift_by_5_wraps_around
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

    inst = @inst_class.new(address: 5, field: 0, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Shifts by 5 mod 5 = 0, so no change... actually shifts by 0
    # Let me check: m % 5 where m = 5 gives 0
    assert_equal [1, 2, 3, 4, 5], @machine.registers.a.bytes
  end

  # SRA - Shift Right A
  def test_sra_shifts_a_right_by_one_position
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

    inst = @inst_class.new(address: 1, field: 1, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Result: [0, 1, 2, 3, 4]
    assert_equal [0, 1, 2, 3, 4], @machine.registers.a.bytes
  end

  def test_sra_shifts_a_right_by_three_positions
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])

    inst = @inst_class.new(address: 3, field: 1, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal [0, 0, 0, 1, 2], @machine.registers.a.bytes
  end

  # SLAX - Shift Left AX
  def test_slax_shifts_ax_left_as_10_byte_register
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

    inst = @inst_class.new(address: 2, field: 2, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Shift 10 bytes [1,2,3,4,5,6,7,8,9,10] left by 2
    # Result: [3,4,5,6,7,8,9,10,0,0]
    assert_equal [3, 4, 5, 6, 7], @machine.registers.a.bytes
    assert_equal [8, 9, 10, 0, 0], @machine.registers.x.bytes
  end

  def test_slax_preserves_signs_of_both_registers
    @machine.registers.a = @word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

    inst = @inst_class.new(address: 1, field: 2, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal -1, @machine.registers.a.sign
    assert_equal 1, @machine.registers.x.sign
  end

  # SRAX - Shift Right AX
  def test_srax_shifts_ax_right_as_10_byte_register
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

    inst = @inst_class.new(address: 3, field: 3, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Shift 10 bytes [1,2,3,4,5,6,7,8,9,10] right by 3
    # Result: [0,0,0,1,2,3,4,5,6,7]
    assert_equal [0, 0, 0, 1, 2], @machine.registers.a.bytes
    assert_equal [3, 4, 5, 6, 7], @machine.registers.x.bytes
  end

  # SLC - Shift Left Circular
  def test_slc_rotates_ax_left
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

    inst = @inst_class.new(address: 2, field: 4, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Rotate [1,2,3,4,5,6,7,8,9,10] left by 2
    # Result: [3,4,5,6,7,8,9,10,1,2]
    assert_equal [3, 4, 5, 6, 7], @machine.registers.a.bytes
    assert_equal [8, 9, 10, 1, 2], @machine.registers.x.bytes
  end

  def test_slc_handles_full_rotation
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

    inst = @inst_class.new(address: 10, field: 4, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Rotate by 10 (full cycle) = no change
    assert_equal [1, 2, 3, 4, 5], @machine.registers.a.bytes
    assert_equal [6, 7, 8, 9, 10], @machine.registers.x.bytes
  end

  # SRC - Shift Right Circular
  def test_src_rotates_ax_right
    @machine.registers.a = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [6, 7, 8, 9, 10])

    inst = @inst_class.new(address: 3, field: 5, opcode: 6)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Rotate [1,2,3,4,5,6,7,8,9,10] right by 3
    # Result: [8,9,10,1,2,3,4,5,6,7]
    assert_equal [8, 9, 10, 1, 2], @machine.registers.a.bytes
    assert_equal [3, 4, 5, 6, 7], @machine.registers.x.bytes
  end

  # MOVE instruction
  def test_move_moves_f_words_from_m_to_location_in_i1
    # Setup source data at locations 100-102
    @machine.memory[100] = @word_class.from_i(10)
    @machine.memory[101] = @word_class.from_i(20)
    @machine.memory[102] = @word_class.from_i(30)

    # Set I1 to destination address 200
    @machine.registers.set_index_i(1, 200)

    # MOVE 100(3) - move 3 words from 100 to I1
    inst = @inst_class.new(address: 100, field: 3, opcode: 7)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Check data was moved
    assert_equal 10, @machine.memory[200].to_i
    assert_equal 20, @machine.memory[201].to_i
    assert_equal 30, @machine.memory[202].to_i

    # Check I1 was updated
    assert_equal 203, @machine.registers.get_index_i(1)
  end

  def test_move_handles_moving_0_words
    @machine.registers.set_index_i(1, 100)

    inst = @inst_class.new(address: 200, field: 0, opcode: 7)
    @machine.memory[0] = inst.to_word

    @machine.step

    # I1 should still be updated (100 + 0 = 100)
    assert_equal 100, @machine.registers.get_index_i(1)
  end

  def test_move_can_move_to_overlapping_locations
    @machine.memory[100] = @word_class.from_i(1)
    @machine.memory[101] = @word_class.from_i(2)
    @machine.memory[102] = @word_class.from_i(3)

    @machine.registers.set_index_i(1, 101)

    # Move from 100 to 101 (overlapping)
    # Word-by-word copy means: mem[101]=mem[100], then mem[102]=mem[101]
    # So mem[102] ends up with the value that was in mem[100] (1, not 2)
    inst = @inst_class.new(address: 100, field: 2, opcode: 7)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 1, @machine.memory[101].to_i
    assert_equal 1, @machine.memory[102].to_i  # Gets copy of mem[101], which is now 1
  end

  # NUM instruction
  def test_num_converts_character_digits_to_numeric_value
    # Setup A:X with character representation of "0000012345"
    # MIX chars 30-39 represent digits 0-9
    @machine.registers.a = @word_class.new(sign: 1, bytes: [30, 30, 30, 30, 30])  # "00000"
    @machine.registers.x = @word_class.new(sign: 1, bytes: [31, 32, 33, 34, 35])  # "12345"

    # NUM instruction
    inst = @inst_class.new(field: 0, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 12345, @machine.registers.a.to_i
  end

  def test_num_handles_negative_sign
    @machine.registers.a = @word_class.new(sign: -1, bytes: [30, 30, 30, 30, 30])
    @machine.registers.x = @word_class.new(sign: -1, bytes: [31, 32, 33, 34, 35])

    inst = @inst_class.new(field: 0, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal(-12345, @machine.registers.a.to_i)
  end

  def test_num_handles_all_zeros
    @machine.registers.a = @word_class.new(sign: 1, bytes: [30, 30, 30, 30, 30])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [30, 30, 30, 30, 30])

    inst = @inst_class.new(field: 0, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 0, @machine.registers.a.to_i
  end

  def test_num_treats_non_digit_characters_as_0
    # Mix some non-digit characters (like 1 = 'A')
    @machine.registers.a = @word_class.new(sign: 1, bytes: [30, 1, 30, 2, 30])
    @machine.registers.x = @word_class.new(sign: 1, bytes: [31, 32, 33, 34, 35])

    inst = @inst_class.new(field: 0, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    # "0A0B012345" -> 0000012345 = 12345
    assert_equal 12345, @machine.registers.a.to_i
  end

  # CHAR instruction
  def test_char_converts_numeric_value_to_character_representation
    @machine.registers.a = @word_class.from_i(12345)

    # CHAR instruction
    inst = @inst_class.new(field: 1, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Should produce "0000012345"
    assert_equal [30, 30, 30, 30, 30], @machine.registers.a.bytes  # "00000"
    assert_equal [31, 32, 33, 34, 35], @machine.registers.x.bytes  # "12345"
  end

  def test_char_preserves_sign
    @machine.registers.a = @word_class.from_i(-12345)

    inst = @inst_class.new(field: 1, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal -1, @machine.registers.a.sign
    assert_equal -1, @machine.registers.x.sign
    # Bytes represent absolute value
    assert_equal [30, 30, 30, 30, 30], @machine.registers.a.bytes
    assert_equal [31, 32, 33, 34, 35], @machine.registers.x.bytes
  end

  def test_char_handles_zero
    @machine.registers.a = @word_class.from_i(0)

    inst = @inst_class.new(field: 1, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    # "0000000000"
    assert_equal [30, 30, 30, 30, 30], @machine.registers.a.bytes
    assert_equal [30, 30, 30, 30, 30], @machine.registers.x.bytes
  end

  def test_char_handles_large_numbers
    # Use max value that fits: 1073741823
    @machine.registers.a = @word_class.from_i(1073741823)

    inst = @inst_class.new(field: 1, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    # "1073741823"
    assert_equal [31, 30, 37, 33, 37], @machine.registers.a.bytes  # "10737"
    assert_equal [34, 31, 38, 32, 33], @machine.registers.x.bytes  # "41823"
  end

  # NUM and CHAR round-trip
  def test_num_and_char_round_trip_converts_number_to_char_and_back
    original = 123456789
    @machine.registers.a = @word_class.from_i(original)

    # CHAR
    char_inst = @inst_class.new(field: 1, opcode: 5)
    @machine.memory[0] = char_inst.to_word
    @machine.step

    # NUM
    num_inst = @inst_class.new(field: 0, opcode: 5)
    @machine.memory[1] = num_inst.to_word
    @machine.step

    assert_equal original, @machine.registers.a.to_i
  end

  # HLT instruction with field specification
  def test_hlt_still_halts_when_using_field_2
    # Verify HLT works with proper field specification
    inst = @inst_class.new(field: 2, opcode: 5)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal true, @machine.halted
  end
end
