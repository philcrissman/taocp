# frozen_string_literal: true

require "test_helper"

class MixCharacterTest < Minitest::Test
  def setup
    @char_class = Taocp::Mix::Character
  end

  # char_to_code tests
  def test_char_to_code_converts_space_to_0
    assert_equal 0, @char_class.char_to_code(" ")
  end

  def test_char_to_code_converts_a_to_z_to_1_to_26
    assert_equal 1, @char_class.char_to_code("A")
    assert_equal 2, @char_class.char_to_code("B")
    assert_equal 26, @char_class.char_to_code("Z")
  end

  def test_char_to_code_converts_0_to_9_to_30_to_39
    assert_equal 30, @char_class.char_to_code("0")
    assert_equal 35, @char_class.char_to_code("5")
    assert_equal 39, @char_class.char_to_code("9")
  end

  def test_char_to_code_converts_punctuation
    assert_equal 40, @char_class.char_to_code(".")
    assert_equal 41, @char_class.char_to_code(",")
    assert_equal 44, @char_class.char_to_code("+")
    assert_equal 45, @char_class.char_to_code("-")
  end

  def test_char_to_code_is_case_insensitive
    assert_equal 1, @char_class.char_to_code("a")
    assert_equal 26, @char_class.char_to_code("z")
  end

  def test_char_to_code_returns_0_for_unknown_characters
    assert_equal 0, @char_class.char_to_code("ñ")
    assert_equal 0, @char_class.char_to_code("€")
  end

  # code_to_char tests
  def test_code_to_char_converts_0_to_space
    assert_equal " ", @char_class.code_to_char(0)
  end

  def test_code_to_char_converts_1_to_26_to_a_to_z
    assert_equal "A", @char_class.code_to_char(1)
    assert_equal "B", @char_class.code_to_char(2)
  end

  def test_code_to_char_converts_30_to_39_to_0_to_9
    assert_equal "0", @char_class.code_to_char(30)
    assert_equal "5", @char_class.code_to_char(35)
    assert_equal "9", @char_class.code_to_char(39)
  end

  def test_code_to_char_handles_out_of_range_codes_gracefully
    assert_equal " ", @char_class.code_to_char(-1)
    assert_equal " ", @char_class.code_to_char(64)
    assert_equal " ", @char_class.code_to_char(100)
  end

  # string_to_codes tests
  def test_string_to_codes_converts_a_string_to_mix_codes
    codes = @char_class.string_to_codes("HELLO")
    # H=8, E=5, L=12, L=12, O=15
    assert_equal [8, 5, 12, 12, 15], codes
  end

  def test_string_to_codes_handles_mixed_case
    codes = @char_class.string_to_codes("HeLLo")
    assert_equal [8, 5, 12, 12, 15], codes
  end

  def test_string_to_codes_handles_spaces
    codes = @char_class.string_to_codes("A B")
    assert_equal [1, 0, 2], codes  # A, space, B
  end

  def test_string_to_codes_handles_digits
    codes = @char_class.string_to_codes("123")
    assert_equal [31, 32, 33], codes  # 1=31, 2=32, 3=33
  end

  # codes_to_string tests
  def test_codes_to_string_converts_mix_codes_back_to_string
    # H=8, E=5, L=12, L=12, O=15
    str = @char_class.codes_to_string([8, 5, 12, 12, 15])
    assert_equal "HELLO", str
  end

  def test_codes_to_string_handles_spaces
    str = @char_class.codes_to_string([1, 0, 2])
    assert_equal "A B", str
  end

  # Round-trip conversion tests
  def test_round_trips_simple_strings
    ["HELLO", "WORLD", "MIX", "TEST123", "A B C"].each do |str|
      codes = @char_class.string_to_codes(str)
      result = @char_class.codes_to_string(codes)
      assert_equal str.upcase, result
    end
  end

  # string_to_words tests
  def test_string_to_words_converts_5_character_string_to_one_word
    words = @char_class.string_to_words("HELLO")
    assert_equal 1, words.length
    assert_equal [8, 5, 12, 12, 15], words[0].bytes
  end

  def test_string_to_words_pads_short_strings_with_spaces
    words = @char_class.string_to_words("HI")
    assert_equal 1, words.length
    assert_equal [8, 9, 0, 0, 0], words[0].bytes  # HI + 3 spaces
  end

  def test_string_to_words_splits_long_strings_into_multiple_words
    words = @char_class.string_to_words("HELLO WORLD")
    assert_equal 3, words.length  # 11 chars -> 3 words (5+5+1 padded)
  end

  def test_string_to_words_creates_words_with_positive_sign
    words = @char_class.string_to_words("TEST")
    assert_equal 1, words[0].sign
  end

  def test_string_to_words_optionally_doesnt_pad
    words = @char_class.string_to_words("HELLO W", pad: false)
    assert_equal 2, words.length
    assert_equal [8, 5, 12, 12, 15], words[0].bytes  # HELLO
    assert_equal [0, 23, 0, 0, 0], words[1].bytes     # " W" + padding for incomplete word
  end

  # words_to_string tests
  def test_words_to_string_converts_words_back_to_string
    words = [
      Taocp::Mix::Word.new(sign: 1, bytes: [8, 5, 12, 12, 15])  # HELLO
    ]
    str = @char_class.words_to_string(words)
    assert_equal "HELLO", str
  end

  def test_words_to_string_handles_multiple_words
    words = [
      Taocp::Mix::Word.new(sign: 1, bytes: [8, 5, 12, 12, 15]),  # HELLO
      Taocp::Mix::Word.new(sign: 1, bytes: [0, 23, 15, 18, 12])  # " WORL"
    ]
    str = @char_class.words_to_string(words)
    assert_equal "HELLO WORL", str
  end

  # Round-trip string/word conversion tests
  def test_round_trips_exact_5_character_strings
    original = "HELLO"
    words = @char_class.string_to_words(original)
    result = @char_class.words_to_string(words)
    assert_equal original, result
  end

  def test_round_trips_with_padding
    original = "HI"
    words = @char_class.string_to_words(original)
    result = @char_class.words_to_string(words)
    assert_equal "HI   ", result  # Padded with spaces
  end

  def test_round_trips_multi_word_strings
    original = "HELLO WORLD"
    words = @char_class.string_to_words(original)
    result = @char_class.words_to_string(words)
    # Will be padded to 15 chars (3 words)
    assert result.start_with?("HELLO WORLD"), "Expected result to start with 'HELLO WORLD', got #{result.inspect}"
  end
end
