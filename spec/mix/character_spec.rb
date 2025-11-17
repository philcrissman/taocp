# frozen_string_literal: true

RSpec.describe Taocp::Mix::Character do
  describe ".char_to_code" do
    it "converts space to 0" do
      expect(described_class.char_to_code(" ")).to eq(0)
    end

    it "converts A-Z to 1-26" do
      expect(described_class.char_to_code("A")).to eq(1)
      expect(described_class.char_to_code("B")).to eq(2)
      expect(described_class.char_to_code("Z")).to eq(26)
    end

    it "converts 0-9 to 30-39" do
      expect(described_class.char_to_code("0")).to eq(30)
      expect(described_class.char_to_code("5")).to eq(35)
      expect(described_class.char_to_code("9")).to eq(39)
    end

    it "converts punctuation" do
      expect(described_class.char_to_code(".")).to eq(40)
      expect(described_class.char_to_code(",")).to eq(41)
      expect(described_class.char_to_code("+")).to eq(44)
      expect(described_class.char_to_code("-")).to eq(45)
    end

    it "is case-insensitive" do
      expect(described_class.char_to_code("a")).to eq(1)
      expect(described_class.char_to_code("z")).to eq(26)
    end

    it "returns 0 for unknown characters" do
      expect(described_class.char_to_code("ñ")).to eq(0)
      expect(described_class.char_to_code("€")).to eq(0)
    end
  end

  describe ".code_to_char" do
    it "converts 0 to space" do
      expect(described_class.code_to_char(0)).to eq(" ")
    end

    it "converts 1-26 to A-Z (partial)" do
      expect(described_class.code_to_char(1)).to eq("A")
      expect(described_class.code_to_char(2)).to eq("B")
    end

    it "converts 30-39 to 0-9" do
      expect(described_class.code_to_char(30)).to eq("0")
      expect(described_class.code_to_char(35)).to eq("5")
      expect(described_class.code_to_char(39)).to eq("9")
    end

    it "handles out-of-range codes gracefully" do
      expect(described_class.code_to_char(-1)).to eq(" ")
      expect(described_class.code_to_char(64)).to eq(" ")
      expect(described_class.code_to_char(100)).to eq(" ")
    end
  end

  describe ".string_to_codes" do
    it "converts a string to MIX codes" do
      codes = described_class.string_to_codes("HELLO")
      # H=8, E=5, L=12, L=12, O=15
      expect(codes).to eq([8, 5, 12, 12, 15])
    end

    it "handles mixed case" do
      codes = described_class.string_to_codes("HeLLo")
      expect(codes).to eq([8, 5, 12, 12, 15])
    end

    it "handles spaces" do
      codes = described_class.string_to_codes("A B")
      expect(codes).to eq([1, 0, 2])  # A, space, B
    end

    it "handles digits" do
      codes = described_class.string_to_codes("123")
      expect(codes).to eq([31, 32, 33])  # 1=31, 2=32, 3=33
    end
  end

  describe ".codes_to_string" do
    it "converts MIX codes back to string" do
      # H=8, E=5, L=12, L=12, O=15
      str = described_class.codes_to_string([8, 5, 12, 12, 15])
      expect(str).to eq("HELLO")
    end

    it "handles spaces" do
      str = described_class.codes_to_string([1, 0, 2])
      expect(str).to eq("A B")
    end
  end

  describe "round-trip conversion" do
    it "round-trips simple strings" do
      ["HELLO", "WORLD", "MIX", "TEST123", "A B C"].each do |str|
        codes = described_class.string_to_codes(str)
        result = described_class.codes_to_string(codes)
        expect(result).to eq(str.upcase)
      end
    end
  end

  describe ".string_to_words" do
    it "converts a 5-character string to one word" do
      words = described_class.string_to_words("HELLO")
      expect(words.length).to eq(1)
      expect(words[0].bytes).to eq([8, 5, 12, 12, 15])
    end

    it "pads short strings with spaces" do
      words = described_class.string_to_words("HI")
      expect(words.length).to eq(1)
      expect(words[0].bytes).to eq([8, 9, 0, 0, 0])  # HI + 3 spaces
    end

    it "splits long strings into multiple words" do
      words = described_class.string_to_words("HELLO WORLD")
      expect(words.length).to eq(3)  # 11 chars -> 3 words (5+5+1 padded)
    end

    it "creates words with positive sign" do
      words = described_class.string_to_words("TEST")
      expect(words[0].sign).to eq(1)
    end

    it "optionally doesn't pad" do
      words = described_class.string_to_words("HELLO W", pad: false)
      expect(words.length).to eq(2)
      expect(words[0].bytes).to eq([8, 5, 12, 12, 15])  # HELLO
      expect(words[1].bytes).to eq([0, 23, 0, 0, 0])     # " W" + padding for incomplete word
    end
  end

  describe ".words_to_string" do
    it "converts words back to string" do
      words = [
        Taocp::Mix::Word.new(sign: 1, bytes: [8, 5, 12, 12, 15])  # HELLO
      ]
      str = described_class.words_to_string(words)
      expect(str).to eq("HELLO")
    end

    it "handles multiple words" do
      words = [
        Taocp::Mix::Word.new(sign: 1, bytes: [8, 5, 12, 12, 15]),  # HELLO
        Taocp::Mix::Word.new(sign: 1, bytes: [0, 23, 15, 18, 12])  # " WORL"
      ]
      str = described_class.words_to_string(words)
      expect(str).to eq("HELLO WORL")
    end
  end

  describe "round-trip string/word conversion" do
    it "round-trips exact 5-character strings" do
      original = "HELLO"
      words = described_class.string_to_words(original)
      result = described_class.words_to_string(words)
      expect(result).to eq(original)
    end

    it "round-trips with padding" do
      original = "HI"
      words = described_class.string_to_words(original)
      result = described_class.words_to_string(words)
      expect(result).to eq("HI   ")  # Padded with spaces
    end

    it "round-trips multi-word strings" do
      original = "HELLO WORLD"
      words = described_class.string_to_words(original)
      result = described_class.words_to_string(words)
      # Will be padded to 15 chars (3 words)
      expect(result).to start_with("HELLO WORLD")
    end
  end
end
