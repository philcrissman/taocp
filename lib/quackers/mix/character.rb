# frozen_string_literal: true

module Quackers
  module Mix
    # MIX Character encoding/decoding
    # Based on TAOCP Section 1.3.1
    module Character
      # MIX character set (6-bit characters, values 0..63)
      # This is a simplified standard encoding
      # Note: TAOCP uses some special characters, but we use a simpler A-Z mapping
      CHAR_TABLE = [
        " ",  # 0
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",  # 1-10
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",  # 11-20
        "U", "V", "W", "X", "Y", "Z",  # 21-26
        "Δ", "Σ", "Π",  # 27-29 (Greek letters for compatibility)
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",  # 30-39
        ".", ",", "(", ")", "+", "-", "*", "/", "=", "$",  # 40-49
        "<", ">", "@", ";", ":", "'",  # 50-55
        # 56-63 are implementation-specific; we'll use some common symbols
        '"', "[", "]", "{", "}", "\\", "^", "_"  # 56-63
      ].freeze

      # Reverse mapping for faster lookups
      CHAR_TO_CODE = CHAR_TABLE.each_with_index.to_h.freeze

      # Convert a character to its MIX code (0..63)
      def self.char_to_code(char)
        code = CHAR_TO_CODE[char.upcase]
        return code if code

        # If character not found, use space (0) as default
        0
      end

      # Convert a MIX code (0..63) to its character
      def self.code_to_char(code)
        return CHAR_TABLE[0] if code < 0 || code >= 64
        CHAR_TABLE[code]
      end

      # Convert a string to MIX character codes
      # Returns an array of codes (0..63)
      def self.string_to_codes(str)
        str.chars.map { |c| char_to_code(c) }
      end

      # Convert MIX character codes to a string
      def self.codes_to_string(codes)
        codes.map { |code| code_to_char(code) }.join
      end

      # Encode a string into MIX words (up to 5 characters per word)
      # Returns an array of Words
      def self.string_to_words(str, pad: true)
        codes = string_to_codes(str)

        # Pad to multiple of 5 if requested
        if pad && codes.length % 5 != 0
          codes += [0] * (5 - (codes.length % 5))
        end

        # Split into groups of 5 and create words
        words = []
        codes.each_slice(5) do |slice|
          # Pad slice if less than 5
          slice += [0] * (5 - slice.length) if slice.length < 5
          words << Word.new(sign: 1, bytes: slice)
        end

        words
      end

      # Decode MIX words to a string
      def self.words_to_string(words)
        codes = words.flat_map(&:bytes)
        codes_to_string(codes)
      end
    end
  end
end
