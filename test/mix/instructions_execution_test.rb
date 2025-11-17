# frozen_string_literal: true

require "test_helper"

class MixInstructionsExecutionTest < Minitest::Test
  def setup
    @machine = Taocp::Mix::Machine.new
    @inst_class = Taocp::Mix::Instruction
    @word_class = Taocp::Mix::Word
  end

  # Load instructions - LDA tests
  def test_lda_loads_a_word_from_memory_into_register_a
    # Store a value in memory
    @machine.memory[100] = @word_class.from_i(12345)

    # Create LDA instruction: LDA 100
    inst = @inst_class.new(address: 100, field: 5, opcode: @inst_class::LDA)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 12345, @machine.registers.a.to_i
  end

  def test_lda_loads_with_field_specification
    # Store word with distinct bytes
    @machine.memory[100] = @word_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

    # LDA 100(1:5) - load bytes only, not sign
    inst = @inst_class.new(address: 100, field: @word_class.encode_field_spec(1, 5), opcode: @inst_class::LDA)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 1, @machine.registers.a.sign  # Positive when not loading sign
    assert_equal [10, 20, 30, 40, 50], @machine.registers.a.bytes
  end

  # Load instructions - LDX tests
  def test_ldx_loads_a_word_into_register_x
    @machine.memory[200] = @word_class.from_i(999)

    inst = @inst_class.new(address: 200, field: 5, opcode: @inst_class::LDX)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 999, @machine.registers.x.to_i
  end

  # Load instructions - LD1-LD6 tests
  def test_ld1_loads_into_index_registers
    @machine.memory[50] = @word_class.from_i(42)

    # LD1 50
    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::LD1)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 42, @machine.registers.get_index_i(1)
  end

  # Store instructions - STA tests
  def test_sta_stores_register_a_to_memory
    @machine.registers.a = @word_class.from_i(777)

    # STA 100
    inst = @inst_class.new(address: 100, field: 5, opcode: @inst_class::STA)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 777, @machine.memory[100].to_i
  end

  def test_sta_stores_with_field_specification
    @machine.registers.a = @word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
    @machine.memory[100] = @word_class.new(sign: 1, bytes: [10, 20, 30, 40, 50])

    # STA 100(3:5) - store bytes 3-5 only
    inst = @inst_class.new(address: 100, field: @word_class.encode_field_spec(3, 5), opcode: @inst_class::STA)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Memory should have original bytes 1-2, then bytes 3-5 from A
    assert_equal 1, @machine.memory[100].sign  # Sign unchanged
    assert_equal [10, 20, 3, 4, 5], @machine.memory[100].bytes
  end

  # Store instructions - STX tests
  def test_stx_stores_register_x_to_memory
    @machine.registers.x = @word_class.from_i(888)

    inst = @inst_class.new(address: 200, field: 5, opcode: @inst_class::STX)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 888, @machine.memory[200].to_i
  end

  # Store instructions - STZ tests
  def test_stz_stores_zero_to_memory
    @machine.memory[150] = @word_class.from_i(999)

    # STZ 150
    inst = @inst_class.new(address: 150, field: 5, opcode: @inst_class::STZ)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 0, @machine.memory[150].to_i
  end

  # Store instructions - STJ tests
  def test_stj_stores_j_register_to_memory
    @machine.registers.j = 123

    inst = @inst_class.new(address: 300, field: 5, opcode: @inst_class::STJ)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 123, @machine.memory[300].to_i
  end

  # Arithmetic instructions - ADD tests
  def test_add_adds_memory_value_to_register_a
    @machine.registers.a = @word_class.from_i(100)
    @machine.memory[50] = @word_class.from_i(200)

    # ADD 50
    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::ADD)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 300, @machine.registers.a.to_i
  end

  def test_add_handles_negative_numbers
    @machine.registers.a = @word_class.from_i(100)
    @machine.memory[50] = @word_class.from_i(-50)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::ADD)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 50, @machine.registers.a.to_i
  end

  def test_add_sets_overflow_flag_on_overflow
    @machine.registers.a = @word_class.from_i(@word_class::MAX_VALUE)
    @machine.memory[50] = @word_class.from_i(1)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::ADD)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal true, @machine.registers.overflow
  end

  # Arithmetic instructions - SUB tests
  def test_sub_subtracts_memory_value_from_register_a
    @machine.registers.a = @word_class.from_i(300)
    @machine.memory[50] = @word_class.from_i(100)

    # SUB 50
    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::SUB)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 200, @machine.registers.a.to_i
  end

  def test_sub_produces_negative_results
    @machine.registers.a = @word_class.from_i(100)
    @machine.memory[50] = @word_class.from_i(200)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::SUB)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal(-100, @machine.registers.a.to_i)
  end

  # Arithmetic instructions - MUL tests
  def test_mul_multiplies_register_a_by_memory_value
    @machine.registers.a = @word_class.from_i(10)
    @machine.memory[50] = @word_class.from_i(20)

    # MUL 50
    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::MUL)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Result is 200, fits in single word
    # High part (rA) should be 0, low part (rX) should be 200
    assert_equal 0, @machine.registers.a.to_i
    assert_equal 200, @machine.registers.x.to_i
  end

  def test_mul_handles_large_products
    @machine.registers.a = @word_class.from_i(1_000_000)
    @machine.memory[50] = @word_class.from_i(1_000)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::MUL)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Result is 1,000,000,000 which exceeds one word
    # Should be split across rA (high) and rX (low)
    result = @machine.registers.a.to_i * (@word_class::MAX_VALUE + 1) + @machine.registers.x.to_i
    assert_equal 1_000_000_000, result
  end

  def test_mul_handles_negative_multiplication
    @machine.registers.a = @word_class.from_i(-10)
    @machine.memory[50] = @word_class.from_i(5)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::MUL)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 0, @machine.registers.a.to_i
    assert_equal(-50, @machine.registers.x.to_i)
  end

  # Arithmetic instructions - DIV tests
  def test_div_divides_ra_rx_by_memory_value
    # For simple division: put value in rX (low word), rA (high word) = 0
    @machine.registers.a = @word_class.from_i(0)
    @machine.registers.x = @word_class.from_i(100)
    @machine.memory[50] = @word_class.from_i(10)

    # DIV 50
    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::DIV)
    @machine.memory[0] = inst.to_word

    @machine.step

    # Quotient in rA, remainder in rX
    assert_equal 10, @machine.registers.a.to_i
    assert_equal 0, @machine.registers.x.to_i
  end

  def test_div_produces_remainder
    # 25 / 7: put 25 in rX, 0 in rA
    @machine.registers.a = @word_class.from_i(0)
    @machine.registers.x = @word_class.from_i(25)
    @machine.memory[50] = @word_class.from_i(7)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::DIV)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 3, @machine.registers.a.to_i   # 25 / 7 = 3
    assert_equal 4, @machine.registers.x.to_i   # 25 % 7 = 4
  end

  def test_div_handles_double_precision_dividend
    # Dividend = 2 * MAX_VALUE + 1000
    @machine.registers.a = @word_class.from_i(2)
    @machine.registers.x = @word_class.from_i(1000)
    @machine.memory[50] = @word_class.from_i(1000)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::DIV)
    @machine.memory[0] = inst.to_word

    @machine.step

    # (2 * MAX_VALUE + 1000) / 1000
    dividend = 2 * (@word_class::MAX_VALUE + 1) + 1000
    expected_quotient = dividend / 1000
    expected_remainder = dividend % 1000

    assert_equal expected_quotient, @machine.registers.a.to_i
    assert_equal expected_remainder, @machine.registers.x.to_i
  end

  def test_div_sets_overflow_on_division_by_zero
    @machine.registers.a = @word_class.from_i(100)
    @machine.memory[50] = @word_class.from_i(0)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::DIV)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal true, @machine.registers.overflow
  end

  # Complete programs tests
  def test_runs_a_simple_arithmetic_program
    # Program: Load 10, add 20, store result, halt
    # Memory[100] = 10
    # Memory[101] = 20
    # Memory[102] = result location

    @machine.memory[100] = @word_class.from_i(10)
    @machine.memory[101] = @word_class.from_i(20)

    # Program at 0-3
    @machine.memory[0] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::LDA).to_word  # LDA 100
    @machine.memory[1] = @inst_class.new(address: 101, field: 5, opcode: @inst_class::ADD).to_word  # ADD 101
    @machine.memory[2] = @inst_class.new(address: 102, field: 5, opcode: @inst_class::STA).to_word  # STA 102
    @machine.memory[3] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word                          # HLT

    @machine.run

    assert_equal 30, @machine.memory[102].to_i
    assert_equal true, @machine.halted
  end

  def test_runs_a_multiplication_program
    # Calculate 12 * 5
    @machine.memory[100] = @word_class.from_i(12)
    @machine.memory[101] = @word_class.from_i(5)

    @machine.memory[0] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::LDA).to_word  # LDA 100
    @machine.memory[1] = @inst_class.new(address: 101, field: 5, opcode: @inst_class::MUL).to_word  # MUL 101
    @machine.memory[2] = @inst_class.new(address: 102, field: 5, opcode: @inst_class::STX).to_word  # STX 102 (result in X)
    @machine.memory[3] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word                          # HLT

    @machine.run

    assert_equal 60, @machine.memory[102].to_i
  end
end
