# frozen_string_literal: true

require "test_helper"

class MixInstructionTest < Minitest::Test
  # Initialization tests
  def test_creates_instruction_with_default_values
    inst = Taocp::Mix::Instruction.new
    assert_equal 0, inst.address
    assert_equal 0, inst.index
    assert_equal 0, inst.field
    assert_equal 0, inst.opcode
    assert_equal 1, inst.sign
  end

  def test_creates_instruction_with_specified_values
    inst = Taocp::Mix::Instruction.new(address: 100, index: 1, field: 5, opcode: 8, sign: -1)
    assert_equal 100, inst.address
    assert_equal 1, inst.index
    assert_equal 5, inst.field
    assert_equal 8, inst.opcode
    assert_equal(-1, inst.sign)
  end

  # to_word tests
  def test_encodes_a_simple_instruction
    inst = Taocp::Mix::Instruction.new(address: 100, index: 1, field: 5, opcode: 8, sign: 1)
    word = inst.to_word

    # 100 = 1*64 + 36
    assert_equal 1, word.sign
    assert_equal [1, 36, 1, 5, 8], word.bytes
  end

  def test_encodes_an_instruction_with_zero_address
    inst = Taocp::Mix::Instruction.new(address: 0, index: 0, field: 0, opcode: Taocp::Mix::Instruction::NOP, sign: 1)
    word = inst.to_word

    assert_equal [0, 0, 0, 0, 0], word.bytes
  end

  def test_encodes_an_instruction_with_maximum_address
    # Max address is 4095 = 63*64 + 63
    inst = Taocp::Mix::Instruction.new(address: 4095, index: 6, field: 5, opcode: 8, sign: -1)
    word = inst.to_word

    assert_equal(-1, word.sign)
    assert_equal [63, 63, 6, 5, 8], word.bytes
  end

  def test_encodes_lda_instruction
    # LDA 2000
    inst = Taocp::Mix::Instruction.new(address: 2000, index: 0, field: 5, opcode: Taocp::Mix::Instruction::LDA)
    word = inst.to_word

    # 2000 = 31*64 + 16
    assert_equal 31, word.bytes[0]
    assert_equal 16, word.bytes[1]
    assert_equal 8, word.bytes[4]  # LDA opcode
  end

  # from_word tests
  def test_decodes_a_simple_instruction
    # 100 = 1*64 + 36
    word = Taocp::Mix::Word.new(sign: 1, bytes: [1, 36, 1, 5, 8])
    inst = Taocp::Mix::Instruction.from_word(word)

    assert_equal 100, inst.address
    assert_equal 1, inst.index
    assert_equal 5, inst.field
    assert_equal 8, inst.opcode
    assert_equal 1, inst.sign
  end

  def test_decodes_nop_instruction
    word = Taocp::Mix::Word.new(sign: 1, bytes: [0, 0, 0, 0, 0])
    inst = Taocp::Mix::Instruction.from_word(word)

    assert_equal 0, inst.address
    assert_equal 0, inst.opcode
  end

  def test_decodes_instruction_with_negative_sign
    word = Taocp::Mix::Word.new(sign: -1, bytes: [0, 50, 2, 13, 8])
    inst = Taocp::Mix::Instruction.from_word(word)

    assert_equal 50, inst.address
    assert_equal(-1, inst.sign)
  end

  # Round-trip encoding tests
  def test_round_trips_simple_instructions
    [
      { address: 0, index: 0, field: 0, opcode: 0, sign: 1 },
      { address: 100, index: 1, field: 5, opcode: 8, sign: 1 },
      { address: 2000, index: 3, field: 13, opcode: 24, sign: -1 },
      { address: 4095, index: 6, field: 63, opcode: 63, sign: 1 },
    ].each do |params|
      original = Taocp::Mix::Instruction.new(**params)
      word = original.to_word
      decoded = Taocp::Mix::Instruction.from_word(word)

      assert_equal original.address, decoded.address
      assert_equal original.index, decoded.index
      assert_equal original.field, decoded.field
      assert_equal original.opcode, decoded.opcode
      assert_equal original.sign, decoded.sign
    end
  end

  # effective_address tests
  def test_returns_address_when_index_is_0
    registers = Taocp::Mix::Registers.new
    inst = Taocp::Mix::Instruction.new(address: 100, index: 0)
    assert_equal 100, inst.effective_address(registers)
  end

  def test_adds_index_register_value_when_index_greater_than_0
    registers = Taocp::Mix::Registers.new
    registers.set_index_i(1, 50)
    inst = Taocp::Mix::Instruction.new(address: 100, index: 1, sign: 1)
    assert_equal 150, inst.effective_address(registers)
  end

  def test_handles_negative_address_sign
    registers = Taocp::Mix::Registers.new
    registers.set_index_i(2, 30)
    inst = Taocp::Mix::Instruction.new(address: 100, index: 2, sign: -1)
    # -100 + 30 = -70, but address is abs = 70
    assert_equal 70, inst.effective_address(registers)
  end

  def test_handles_zero_index_register
    registers = Taocp::Mix::Registers.new
    registers.set_index_i(3, 0)
    inst = Taocp::Mix::Instruction.new(address: 200, index: 3)
    assert_equal 200, inst.effective_address(registers)
  end

  def test_uses_different_index_registers
    registers = Taocp::Mix::Registers.new
    (1..6).each do |i|
      registers.set_index_i(i, i * 10)
      inst = Taocp::Mix::Instruction.new(address: 100, index: i)
      assert_equal 100 + i * 10, inst.effective_address(registers)
    end
  end

  # Opcode constants tests
  def test_defines_load_opcodes
    assert_equal 8, Taocp::Mix::Instruction::LDA
    assert_equal 15, Taocp::Mix::Instruction::LDX
    assert_equal 9, Taocp::Mix::Instruction::LD1
  end

  def test_defines_store_opcodes
    assert_equal 24, Taocp::Mix::Instruction::STA
    assert_equal 31, Taocp::Mix::Instruction::STX
    assert_equal 33, Taocp::Mix::Instruction::STZ
  end

  def test_defines_arithmetic_opcodes
    assert_equal 1, Taocp::Mix::Instruction::ADD
    assert_equal 2, Taocp::Mix::Instruction::SUB
    assert_equal 3, Taocp::Mix::Instruction::MUL
    assert_equal 4, Taocp::Mix::Instruction::DIV
  end

  def test_defines_comparison_opcodes
    assert_equal 56, Taocp::Mix::Instruction::CMPA
    assert_equal 63, Taocp::Mix::Instruction::CMPX
  end

  def test_defines_special_opcodes
    assert_equal 0, Taocp::Mix::Instruction::NOP
    assert_equal 5, Taocp::Mix::Instruction::HLT
  end

  # to_s tests
  def test_formats_instruction_as_string
    inst = Taocp::Mix::Instruction.new(address: 100, index: 1, field: 5, opcode: 8)
    assert_equal "+0100 1 5 8", inst.to_s
  end

  def test_formats_negative_instruction
    inst = Taocp::Mix::Instruction.new(address: 50, index: 2, field: 13, opcode: 24, sign: -1)
    assert_equal "-0050 2 13 24", inst.to_s
  end
end
