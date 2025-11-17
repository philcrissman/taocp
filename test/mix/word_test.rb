# frozen_string_literal: true

require "test_helper"

class MixWordTest < Minitest::Test
  def setup
    @word_class = Taocp::Mix::Word
  end

  # Initialization tests
  def test_creates_word_with_default_values
    word = @word_class.new
    assert_equal 1, word.sign
    assert_equal [0, 0, 0, 0, 0], word.bytes
  end

  def test_creates_word_with_specified_sign_and_bytes
    word = @word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
    assert_equal(-1, word.sign)
    assert_equal [1, 2, 3, 4, 5], word.bytes
  end

  def test_validates_sign_is_plus_or_minus_one
    assert_raises(ArgumentError, /Sign must be/) { @word_class.new(sign: 0) }
    assert_raises(ArgumentError, /Sign must be/) { @word_class.new(sign: 2) }
  end

  def test_validates_exactly_5_bytes
    assert_raises(ArgumentError, /exactly 5 bytes/) { @word_class.new(bytes: [1, 2, 3]) }
    assert_raises(ArgumentError, /exactly 5 bytes/) { @word_class.new(bytes: [1, 2, 3, 4, 5, 6]) }
  end

  def test_validates_bytes_are_in_range_0_to_63
    assert_raises(ArgumentError, /Byte 1 must be/) { @word_class.new(bytes: [-1, 0, 0, 0, 0]) }
    assert_raises(ArgumentError, /Byte 5 must be/) { @word_class.new(bytes: [0, 0, 0, 0, 64]) }
  end

  # to_i tests
  def test_converts_zero_correctly
    word = @word_class.new(sign: 1, bytes: [0, 0, 0, 0, 0])
    assert_equal 0, word.to_i
  end

  def test_converts_positive_numbers_correctly
    # 1 in MIX
    word = @word_class.new(sign: 1, bytes: [0, 0, 0, 0, 1])
    assert_equal 1, word.to_i

    # 64 in MIX (one in byte 4)
    word = @word_class.new(sign: 1, bytes: [0, 0, 0, 1, 0])
    assert_equal 64, word.to_i

    # 65 in MIX
    word = @word_class.new(sign: 1, bytes: [0, 0, 0, 1, 1])
    assert_equal 65, word.to_i
  end

  def test_converts_negative_numbers_correctly
    word = @word_class.new(sign: -1, bytes: [0, 0, 0, 0, 1])
    assert_equal(-1, word.to_i)

    word = @word_class.new(sign: -1, bytes: [0, 0, 0, 1, 0])
    assert_equal(-64, word.to_i)
  end

  def test_converts_maximum_value_correctly
    # All bytes set to 63
    max_word = @word_class.new(sign: 1, bytes: [63, 63, 63, 63, 63])
    assert_equal @word_class::MAX_VALUE, max_word.to_i
    assert_equal 1_073_741_823, max_word.to_i
  end

  def test_handles_larger_multi_byte_values
    # 1000 = 15*64 + 40
    word = @word_class.new(sign: 1, bytes: [0, 0, 0, 15, 40])
    assert_equal 1000, word.to_i

    # 100000 = 24*64^2 + 26*64 + 32
    word = @word_class.new(sign: 1, bytes: [0, 0, 24, 26, 32])
    assert_equal 100_000, word.to_i
  end

  # from_i tests
  def test_from_i_creates_zero_correctly
    word = @word_class.from_i(0)
    assert_equal 1, word.sign
    assert_equal [0, 0, 0, 0, 0], word.bytes
  end

  def test_from_i_creates_small_positive_numbers_correctly
    word = @word_class.from_i(1)
    assert_equal 1, word.sign
    assert_equal [0, 0, 0, 0, 1], word.bytes

    word = @word_class.from_i(63)
    assert_equal 1, word.sign
    assert_equal [0, 0, 0, 0, 63], word.bytes
  end

  def test_from_i_creates_small_negative_numbers_correctly
    word = @word_class.from_i(-1)
    assert_equal(-1, word.sign)
    assert_equal [0, 0, 0, 0, 1], word.bytes

    word = @word_class.from_i(-63)
    assert_equal(-1, word.sign)
    assert_equal [0, 0, 0, 0, 63], word.bytes
  end

  def test_from_i_creates_multi_byte_numbers_correctly
    # 64 = [0, 0, 0, 1, 0]
    word = @word_class.from_i(64)
    assert_equal [0, 0, 0, 1, 0], word.bytes

    # 1000 = 15*64 + 40
    word = @word_class.from_i(1000)
    assert_equal [0, 0, 0, 15, 40], word.bytes

    # 100000 = 24*64^2 + 26*64 + 32
    word = @word_class.from_i(100_000)
    assert_equal [0, 0, 24, 26, 32], word.bytes
  end

  def test_from_i_creates_maximum_value_correctly
    word = @word_class.from_i(@word_class::MAX_VALUE)
    assert_equal [63, 63, 63, 63, 63], word.bytes
  end

  def test_from_i_raises_error_for_values_exceeding_capacity
    too_large = @word_class::MAX_VALUE + 1
    assert_raises(ArgumentError, /exceeds/) { @word_class.from_i(too_large) }

    too_negative = -(@word_class::MAX_VALUE + 1)
    assert_raises(ArgumentError, /exceeds/) { @word_class.from_i(too_negative) }
  end

  # Round-trip conversion tests
  def test_round_trips_positive_numbers
    test_values = [0, 1, 63, 64, 100, 1000, 10_000, 100_000, 1_000_000, @word_class::MAX_VALUE]
    test_values.each do |n|
      word = @word_class.from_i(n)
      assert_equal n, word.to_i, "Failed for #{n}"
    end
  end

  def test_round_trips_negative_numbers
    test_values = [-1, -63, -64, -100, -1000, -10_000, -100_000, -1_000_000, -@word_class::MAX_VALUE]
    test_values.each do |n|
      word = @word_class.from_i(n)
      assert_equal n, word.to_i, "Failed for #{n}"
    end
  end

  def test_round_trips_random_values
    100.times do
      n = rand(-@word_class::MAX_VALUE..@word_class::MAX_VALUE)
      word = @word_class.from_i(n)
      assert_equal n, word.to_i, "Failed for #{n}"
    end
  end

  # slice tests
  def test_slice_extracts_sign_only_with_0_0
    word = @word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
    slice = word.slice(0, 0)

    assert_equal(-1, slice.sign)
    assert_equal [0, 0, 0, 0, 0], slice.bytes
  end

  def test_slice_extracts_whole_word_with_0_5
    word = @word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
    slice = word.slice(0, 5)

    assert_equal(-1, slice.sign)
    assert_equal [1, 2, 3, 4, 5], slice.bytes
    assert_equal word, slice
  end

  def test_slice_extracts_bytes_without_sign_with_1_5
    word = @word_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
    slice = word.slice(1, 5)

    assert_equal 1, slice.sign  # Positive when L > 0
    assert_equal [1, 2, 3, 4, 5], slice.bytes
  end

  def test_slice_extracts_single_byte_with_1_1
    word = @word_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])
    slice = word.slice(1, 1)

    assert_equal 1, slice.sign
    assert_equal [0, 0, 0, 0, 10], slice.bytes
  end

  def test_slice_extracts_byte_range_2_4
    word = @word_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])
    slice = word.slice(2, 4)

    assert_equal 1, slice.sign
    # Bytes 2, 3, 4 -> right-aligned
    assert_equal [0, 0, 20, 30, 40], slice.bytes
  end

  def test_slice_extracts_byte_range_3_5
    word = @word_class.new(sign: 1, bytes: [10, 20, 30, 40, 50])
    slice = word.slice(3, 5)

    assert_equal 1, slice.sign
    # Bytes 3, 4, 5 -> right-aligned
    assert_equal [0, 0, 30, 40, 50], slice.bytes
  end

  def test_slice_validates_field_specifications
    word = @word_class.new

    assert_raises(ArgumentError, /Left field spec/) { word.slice(-1, 5) }
    assert_raises(ArgumentError, /Right field spec/) { word.slice(0, 6) }
    assert_raises(ArgumentError, /Left must be <= right/) { word.slice(3, 2) }
  end

  # store_slice! tests
  def test_store_slice_stores_sign_only_with_0_0
    word = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    source = @word_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

    word.store_slice!(0, 0, source)

    assert_equal(-1, word.sign)
    assert_equal [1, 2, 3, 4, 5], word.bytes  # Bytes unchanged
  end

  def test_store_slice_stores_whole_word_with_0_5
    word = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    source = @word_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

    word.store_slice!(0, 5, source)

    assert_equal(-1, word.sign)
    assert_equal [10, 20, 30, 40, 50], word.bytes
  end

  def test_store_slice_stores_bytes_without_sign_with_1_5
    word = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    source = @word_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

    word.store_slice!(1, 5, source)

    assert_equal 1, word.sign  # Sign unchanged
    assert_equal [10, 20, 30, 40, 50], word.bytes
  end

  def test_store_slice_stores_single_byte_with_5_5
    word = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    source = @word_class.new(sign: -1, bytes: [0, 0, 0, 0, 63])

    word.store_slice!(5, 5, source)

    assert_equal 1, word.sign
    assert_equal [1, 2, 3, 4, 63], word.bytes
  end

  def test_store_slice_stores_byte_range_2_4
    word = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    # Source has values in last 3 bytes
    source = @word_class.new(sign: -1, bytes: [0, 0, 11, 22, 33])

    word.store_slice!(2, 4, source)

    assert_equal 1, word.sign
    assert_equal [1, 11, 22, 33, 5], word.bytes
  end

  def test_store_slice_stores_byte_range_1_3
    word = @word_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
    source = @word_class.new(sign: -1, bytes: [0, 0, 10, 20, 30])

    word.store_slice!(1, 3, source)

    assert_equal 1, word.sign
    assert_equal [10, 20, 30, 4, 5], word.bytes
  end

  def test_store_slice_validates_field_specifications
    word = @word_class.new
    source = @word_class.new

    assert_raises(ArgumentError, /Left field spec/) { word.store_slice!(-1, 5, source) }
    assert_raises(ArgumentError, /Right field spec/) { word.store_slice!(0, 6, source) }
    assert_raises(ArgumentError, /Left must be <= right/) { word.store_slice!(3, 2, source) }
  end

  def test_store_slice_validates_source_is_a_word
    word = @word_class.new
    assert_raises(ArgumentError, /Source must be a Word/) { word.store_slice!(0, 5, 42) }
  end

  def test_store_slice_returns_self_for_chaining
    word = @word_class.new
    source = @word_class.new
    result = word.store_slice!(0, 5, source)
    assert_same word, result
  end

  # Field spec encoding/decoding tests
  def test_encode_field_spec
    assert_equal 5, @word_class.encode_field_spec(0, 5)
    assert_equal 13, @word_class.encode_field_spec(1, 5)
    assert_equal 0, @word_class.encode_field_spec(0, 0)
    assert_equal 29, @word_class.encode_field_spec(3, 5)
  end

  def test_decode_field_spec
    assert_equal [0, 5], @word_class.decode_field_spec(5)
    assert_equal [1, 5], @word_class.decode_field_spec(13)
    assert_equal [0, 0], @word_class.decode_field_spec(0)
    assert_equal [3, 5], @word_class.decode_field_spec(29)
  end

  def test_field_spec_round_trips_encoding_and_decoding
    (0..5).each do |l|
      (l..5).each do |r|
        encoded = @word_class.encode_field_spec(l, r)
        decoded = @word_class.decode_field_spec(encoded)
        assert_equal [l, r], decoded
      end
    end
  end

  # Equality tests
  def test_compares_words_correctly
    word1 = @word_class.new(sign: 1, bytes: [0, 0, 0, 0, 5])
    word2 = @word_class.new(sign: 1, bytes: [0, 0, 0, 0, 5])
    word3 = @word_class.new(sign: -1, bytes: [0, 0, 0, 0, 5])

    assert_equal word2, word1
    refute_equal word3, word1
  end

  def test_distinguishes_positive_zero_from_negative_zero
    positive_zero = @word_class.new(sign: 1, bytes: [0, 0, 0, 0, 0])
    negative_zero = @word_class.new(sign: -1, bytes: [0, 0, 0, 0, 0])

    refute_equal negative_zero, positive_zero
  end

  # from_alf tests
  def test_from_alf_creates_word_from_5_character_string
    word = @word_class.from_alf("HELLO")
    # H=8, E=5, L=12, L=12, O=15
    assert_equal [8, 5, 12, 12, 15], word.bytes
    assert_equal 1, word.sign
  end

  def test_from_alf_pads_short_strings_with_spaces
    word = @word_class.from_alf("HI")
    # H=8, I=9, then 3 spaces
    assert_equal [8, 9, 0, 0, 0], word.bytes
  end

  def test_from_alf_handles_single_characters
    word = @word_class.from_alf("A")
    assert_equal [1, 0, 0, 0, 0], word.bytes
  end

  def test_from_alf_handles_empty_string
    word = @word_class.from_alf("")
    assert_equal [0, 0, 0, 0, 0], word.bytes
  end

  def test_from_alf_raises_error_for_strings_longer_than_5_characters
    assert_raises(ArgumentError, /too long/) { @word_class.from_alf("TOOLONG") }
  end

  def test_from_alf_is_case_insensitive
    word1 = @word_class.from_alf("HELLO")
    word2 = @word_class.from_alf("hello")
    assert_equal word2, word1
  end

  # to_alf tests
  def test_to_alf_converts_word_to_string
    word = @word_class.new(sign: 1, bytes: [8, 5, 12, 12, 15])
    assert_equal "HELLO", word.to_alf
  end

  def test_to_alf_converts_spaces_correctly
    word = @word_class.new(sign: 1, bytes: [8, 9, 0, 0, 0])
    assert_equal "HI   ", word.to_alf
  end

  def test_to_alf_converts_all_spaces_to_space_string
    word = @word_class.new(sign: 1, bytes: [0, 0, 0, 0, 0])
    assert_equal "     ", word.to_alf
  end

  def test_to_alf_ignores_sign
    word = @word_class.new(sign: -1, bytes: [8, 5, 12, 12, 15])
    assert_equal "HELLO", word.to_alf
  end

  # ALF round-trip tests
  def test_alf_round_trips_5_character_strings
    ["HELLO", "WORLD", "MIX01", "12345", "A B C"].each do |str|
      word = @word_class.from_alf(str)
      result = word.to_alf
      assert_equal str.upcase, result
    end
  end

  def test_alf_round_trips_short_strings_with_padding
    word = @word_class.from_alf("HI")
    assert_equal "HI   ", word.to_alf
  end
end
