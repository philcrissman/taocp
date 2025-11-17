# frozen_string_literal: true

require "test_helper"

class ComparisonJumpTest < Minitest::Test
  def setup
    @machine = Taocp::Mix::Machine.new
    @inst_class = Taocp::Mix::Instruction
    @word_class = Taocp::Mix::Word
  end

  # Comparison instructions - CMPA
  def test_cmpa_sets_comparison_flag_to_less_when_a_less_than_memory
    @machine.registers.a = @word_class.from_i(10)
    @machine.memory[100] = @word_class.from_i(20)

    inst = @inst_class.new(address: 100, field: 5, opcode: @inst_class::CMPA)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal :less, @machine.registers.comparison_flag
  end

  def test_cmpa_sets_comparison_flag_to_equal_when_a_equals_memory
    @machine.registers.a = @word_class.from_i(15)
    @machine.memory[100] = @word_class.from_i(15)

    inst = @inst_class.new(address: 100, field: 5, opcode: @inst_class::CMPA)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal :equal, @machine.registers.comparison_flag
  end

  def test_cmpa_sets_comparison_flag_to_greater_when_a_greater_than_memory
    @machine.registers.a = @word_class.from_i(30)
    @machine.memory[100] = @word_class.from_i(10)

    inst = @inst_class.new(address: 100, field: 5, opcode: @inst_class::CMPA)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal :greater, @machine.registers.comparison_flag
  end

  def test_cmpa_handles_negative_numbers
    @machine.registers.a = @word_class.from_i(-5)
    @machine.memory[100] = @word_class.from_i(10)

    inst = @inst_class.new(address: 100, field: 5, opcode: @inst_class::CMPA)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal :less, @machine.registers.comparison_flag
  end

  # Comparison instructions - CMPX
  def test_cmpx_compares_register_x_with_memory
    @machine.registers.x = @word_class.from_i(100)
    @machine.memory[50] = @word_class.from_i(50)

    inst = @inst_class.new(address: 50, field: 5, opcode: @inst_class::CMPX)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal :greater, @machine.registers.comparison_flag
  end

  # Comparison instructions - CMP1-CMP6
  def test_cmp1_compares_index_registers
    @machine.registers.set_index_i(1, 42)
    @machine.memory[100] = @word_class.from_i(42)

    inst = @inst_class.new(address: 100, field: 5, opcode: @inst_class::CMP1)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal :equal, @machine.registers.comparison_flag
  end

  # Jump instructions - JMP
  def test_jmp_unconditional_jump_to_address_and_saves_return_address_in_j
    # JMP 200 (field=0 for unconditional)
    inst = @inst_class.new(address: 200, field: 0, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 200, @machine.pc
    assert_equal 1, @machine.registers.j  # Return address (PC after fetch)
  end

  # Jump instructions - JSJ
  def test_jsj_jumps_but_does_not_modify_j_register
    @machine.registers.j = 999

    inst = @inst_class.new(address: 300, field: 1, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 300, @machine.pc
    assert_equal 999, @machine.registers.j  # Unchanged
  end

  # Jump instructions - JOV
  def test_jov_jumps_when_overflow_is_set
    @machine.registers.overflow = true

    inst = @inst_class.new(address: 100, field: 2, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 100, @machine.pc
    assert_equal false, @machine.registers.overflow  # Reset after jump
  end

  def test_jov_does_not_jump_when_overflow_is_not_set
    @machine.registers.overflow = false

    inst = @inst_class.new(address: 100, field: 2, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 1, @machine.pc  # No jump
  end

  # Jump instructions - JL
  def test_jl_jumps_when_comparison_flag_is_less
    @machine.registers.comparison_flag = :less

    inst = @inst_class.new(address: 150, field: 4, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 150, @machine.pc
  end

  def test_jl_does_not_jump_when_comparison_flag_is_not_less
    @machine.registers.comparison_flag = :equal

    inst = @inst_class.new(address: 150, field: 4, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 1, @machine.pc
  end

  # Jump instructions - JE
  def test_je_jumps_when_comparison_flag_is_equal
    @machine.registers.comparison_flag = :equal

    inst = @inst_class.new(address: 200, field: 5, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 200, @machine.pc
  end

  # Jump instructions - JG
  def test_jg_jumps_when_comparison_flag_is_greater
    @machine.registers.comparison_flag = :greater

    inst = @inst_class.new(address: 250, field: 6, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 250, @machine.pc
  end

  # Jump instructions - JGE
  def test_jge_jumps_when_comparison_flag_is_greater
    @machine.registers.comparison_flag = :greater

    inst = @inst_class.new(address: 300, field: 7, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 300, @machine.pc
  end

  def test_jge_jumps_when_comparison_flag_is_equal
    @machine.registers.comparison_flag = :equal

    inst = @inst_class.new(address: 300, field: 7, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 300, @machine.pc
  end

  def test_jge_does_not_jump_when_comparison_flag_is_less
    @machine.registers.comparison_flag = :less

    inst = @inst_class.new(address: 300, field: 7, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 1, @machine.pc
  end

  # Jump instructions - JNE
  def test_jne_jumps_when_comparison_flag_is_not_equal
    @machine.registers.comparison_flag = :less

    inst = @inst_class.new(address: 400, field: 8, opcode: @inst_class::JMP)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 400, @machine.pc
  end

  # Jump instructions - JLE
  def test_jle_jumps_when_comparison_flag_is_less_or_equal
    [:less, :equal].each do |flag|
      @machine.reset
      @machine.registers.comparison_flag = flag

      inst = @inst_class.new(address: 500, field: 9, opcode: @inst_class::JMP)
      @machine.memory[0] = inst.to_word

      @machine.step

      assert_equal 500, @machine.pc
    end
  end

  # JAN - Jump on A conditions - JAN (negative)
  def test_jan_jumps_when_a_is_negative
    @machine.registers.a = @word_class.from_i(-10)

    inst = @inst_class.new(address: 100, field: 0, opcode: @inst_class::JAN)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 100, @machine.pc
  end

  def test_jan_does_not_jump_when_a_is_positive_or_zero
    [0, 10].each do |value|
      @machine.reset
      @machine.registers.a = @word_class.from_i(value)

      inst = @inst_class.new(address: 100, field: 0, opcode: @inst_class::JAN)
      @machine.memory[0] = inst.to_word

      @machine.step

      assert_equal 1, @machine.pc
    end
  end

  # JAN - Jump on A conditions - JAZ (zero)
  def test_jaz_jumps_when_a_is_zero
    @machine.registers.a = @word_class.from_i(0)

    inst = @inst_class.new(address: 200, field: 1, opcode: @inst_class::JAN)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 200, @machine.pc
  end

  # JAN - Jump on A conditions - JAP (positive)
  def test_jap_jumps_when_a_is_positive
    @machine.registers.a = @word_class.from_i(5)

    inst = @inst_class.new(address: 300, field: 2, opcode: @inst_class::JAN)
    @machine.memory[0] = inst.to_word

    @machine.step

    assert_equal 300, @machine.pc
  end

  # JAN - Jump on A conditions - JANN (non-negative)
  def test_jann_jumps_when_a_is_zero_or_positive
    [0, 10].each do |value|
      @machine.reset
      @machine.registers.a = @word_class.from_i(value)

      inst = @inst_class.new(address: 400, field: 3, opcode: @inst_class::JAN)
      @machine.memory[0] = inst.to_word

      @machine.step

      assert_equal 400, @machine.pc
    end
  end

  # JAN - Jump on A conditions - JANZ (non-zero)
  def test_janz_jumps_when_a_is_not_zero
    [-5, 5].each do |value|
      @machine.reset
      @machine.registers.a = @word_class.from_i(value)

      inst = @inst_class.new(address: 500, field: 4, opcode: @inst_class::JAN)
      @machine.memory[0] = inst.to_word

      @machine.step

      assert_equal 500, @machine.pc
    end
  end

  # JAN - Jump on A conditions - JANP (non-positive)
  def test_janp_jumps_when_a_is_zero_or_negative
    [0, -10].each do |value|
      @machine.reset
      @machine.registers.a = @word_class.from_i(value)

      inst = @inst_class.new(address: 600, field: 5, opcode: @inst_class::JAN)
      @machine.memory[0] = inst.to_word

      @machine.step

      assert_equal 600, @machine.pc
    end
  end

  # Loop programs
  def test_counts_down_from_10_to_0_using_a_loop
    # Program: Initialize counter to 10, decrement, loop until zero
    # Memory layout:
    # [100] = counter (initial value 10)
    # [101] = decrement value (-1)
    # [0-4] = program

    @machine.memory[100] = @word_class.from_i(10)
    @machine.memory[101] = @word_class.from_i(-1)

    # Program:
    # 0: LDA 100      - Load counter into A
    # 1: ADD 101      - Add -1 (decrement)
    # 2: STA 100      - Store back to counter
    # 3: JAP 0        - Jump to 0 if A is positive
    # 4: HLT          - Halt when counter reaches 0

    @machine.memory[0] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::LDA).to_word
    @machine.memory[1] = @inst_class.new(address: 101, field: 5, opcode: @inst_class::ADD).to_word
    @machine.memory[2] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::STA).to_word
    @machine.memory[3] = @inst_class.new(address: 0, field: 2, opcode: @inst_class::JAN).to_word  # JAP
    @machine.memory[4] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    @machine.run

    # Should have executed: 10 iterations * 4 instructions + 1 final HLT
    # Each iteration: LDA, ADD, STA, JAP (4 instructions)
    # Last iteration: LDA, ADD, STA, JAP (doesn't jump), HLT
    assert_equal 0, @machine.memory[100].to_i
    assert_equal true, @machine.halted
    assert_equal 0, @machine.registers.a.to_i
  end

  def test_calculates_factorial_of_5_using_a_loop
    # Calculate 5! = 120
    # Memory layout:
    # [100] = n (5)
    # [101] = result (accumulated product, starts at 1)
    # [102] = constant 1

    @machine.memory[100] = @word_class.from_i(5)     # n
    @machine.memory[101] = @word_class.from_i(1)     # result = 1
    @machine.memory[102] = @word_class.from_i(-1)    # decrement

    # Program:
    # 0: LDA 101      - Load result
    # 1: MUL 100      - Multiply by n
    # 2: STX 101      - Store result (MUL result is in rX)
    # 3: LDA 100      - Load n
    # 4: ADD 102      - Decrement n
    # 5: STA 100      - Store n
    # 6: JAP 0        - If n > 0, loop
    # 7: HLT

    @machine.memory[0] = @inst_class.new(address: 101, field: 5, opcode: @inst_class::LDA).to_word
    @machine.memory[1] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::MUL).to_word
    @machine.memory[2] = @inst_class.new(address: 101, field: 5, opcode: @inst_class::STX).to_word
    @machine.memory[3] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::LDA).to_word
    @machine.memory[4] = @inst_class.new(address: 102, field: 5, opcode: @inst_class::ADD).to_word
    @machine.memory[5] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::STA).to_word
    @machine.memory[6] = @inst_class.new(address: 0, field: 2, opcode: @inst_class::JAN).to_word  # JAP
    @machine.memory[7] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    @machine.run

    assert_equal 120, @machine.memory[101].to_i  # 5! = 120
    assert_equal true, @machine.halted
  end

  def test_uses_comparison_and_conditional_jump
    # Find if 15 is less than, equal to, or greater than 20
    @machine.memory[100] = @word_class.from_i(15)
    @machine.memory[101] = @word_class.from_i(20)

    # Program:
    # 0: LDA 100      - Load first number
    # 1: CMPA 101     - Compare with second number
    # 2: JL 10        - Jump to 10 if less
    # 3: JE 20        - Jump to 20 if equal
    # 4: JG 30        - Jump to 30 if greater
    # 10: LDA constant 1 (less)
    # 11: STA 200
    # 12: HLT
    # 20: LDA constant 2 (equal)
    # 21: STA 200
    # 22: HLT
    # 30: LDA constant 3 (greater)
    # 31: STA 200
    # 32: HLT

    @machine.memory[0] = @inst_class.new(address: 100, field: 5, opcode: @inst_class::LDA).to_word
    @machine.memory[1] = @inst_class.new(address: 101, field: 5, opcode: @inst_class::CMPA).to_word
    @machine.memory[2] = @inst_class.new(address: 10, field: 4, opcode: @inst_class::JMP).to_word  # JL
    @machine.memory[3] = @inst_class.new(address: 20, field: 5, opcode: @inst_class::JMP).to_word  # JE
    @machine.memory[4] = @inst_class.new(address: 30, field: 6, opcode: @inst_class::JMP).to_word  # JG

    # Less path (address 10)
    @machine.memory[10] = @inst_class.new(address: 150, field: 5, opcode: @inst_class::LDA).to_word
    @machine.memory[11] = @inst_class.new(address: 200, field: 5, opcode: @inst_class::STA).to_word
    @machine.memory[12] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    # Equal path (address 20) - won't be used
    @machine.memory[20] = @inst_class.new(address: 151, field: 5, opcode: @inst_class::LDA).to_word
    @machine.memory[21] = @inst_class.new(address: 200, field: 5, opcode: @inst_class::STA).to_word
    @machine.memory[22] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    # Greater path (address 30) - won't be used
    @machine.memory[30] = @inst_class.new(address: 152, field: 5, opcode: @inst_class::LDA).to_word
    @machine.memory[31] = @inst_class.new(address: 200, field: 5, opcode: @inst_class::STA).to_word
    @machine.memory[32] = @inst_class.new(opcode: @inst_class::HLT, field: 2).to_word

    # Values to load
    @machine.memory[150] = @word_class.from_i(1)  # "less" marker
    @machine.memory[151] = @word_class.from_i(2)  # "equal" marker
    @machine.memory[152] = @word_class.from_i(3)  # "greater" marker

    @machine.run

    assert_equal 1, @machine.memory[200].to_i  # Should have taken "less" path
    assert_equal true, @machine.halted
  end
end
