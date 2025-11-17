# frozen_string_literal: true

RSpec.describe Taocp::Mix::Word do
  describe "initialization" do
    it "creates a word with default values" do
      word = described_class.new
      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([0, 0, 0, 0, 0])
    end

    it "creates a word with specified sign and bytes" do
      word = described_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
      expect(word.sign).to eq(-1)
      expect(word.bytes).to eq([1, 2, 3, 4, 5])
    end

    it "validates sign is +1 or -1" do
      expect { described_class.new(sign: 0) }.to raise_error(ArgumentError, /Sign must be/)
      expect { described_class.new(sign: 2) }.to raise_error(ArgumentError, /Sign must be/)
    end

    it "validates exactly 5 bytes" do
      expect { described_class.new(bytes: [1, 2, 3]) }.to raise_error(ArgumentError, /exactly 5 bytes/)
      expect { described_class.new(bytes: [1, 2, 3, 4, 5, 6]) }.to raise_error(ArgumentError, /exactly 5 bytes/)
    end

    it "validates bytes are in range 0..63" do
      expect { described_class.new(bytes: [-1, 0, 0, 0, 0]) }.to raise_error(ArgumentError, /Byte 1 must be/)
      expect { described_class.new(bytes: [0, 0, 0, 0, 64]) }.to raise_error(ArgumentError, /Byte 5 must be/)
    end
  end

  describe "#to_i" do
    it "converts zero correctly" do
      word = described_class.new(sign: 1, bytes: [0, 0, 0, 0, 0])
      expect(word.to_i).to eq(0)
    end

    it "converts positive numbers correctly" do
      # 1 in MIX
      word = described_class.new(sign: 1, bytes: [0, 0, 0, 0, 1])
      expect(word.to_i).to eq(1)

      # 64 in MIX (one in byte 4)
      word = described_class.new(sign: 1, bytes: [0, 0, 0, 1, 0])
      expect(word.to_i).to eq(64)

      # 65 in MIX
      word = described_class.new(sign: 1, bytes: [0, 0, 0, 1, 1])
      expect(word.to_i).to eq(65)
    end

    it "converts negative numbers correctly" do
      word = described_class.new(sign: -1, bytes: [0, 0, 0, 0, 1])
      expect(word.to_i).to eq(-1)

      word = described_class.new(sign: -1, bytes: [0, 0, 0, 1, 0])
      expect(word.to_i).to eq(-64)
    end

    it "converts maximum value correctly" do
      # All bytes set to 63
      max_word = described_class.new(sign: 1, bytes: [63, 63, 63, 63, 63])
      expect(max_word.to_i).to eq(described_class::MAX_VALUE)
      expect(max_word.to_i).to eq(1_073_741_823)
    end

    it "handles larger multi-byte values" do
      # 1000 = 15*64 + 40
      word = described_class.new(sign: 1, bytes: [0, 0, 0, 15, 40])
      expect(word.to_i).to eq(1000)

      # 100000 = 24*64^2 + 26*64 + 32
      word = described_class.new(sign: 1, bytes: [0, 0, 24, 26, 32])
      expect(word.to_i).to eq(100_000)
    end
  end

  describe ".from_i" do
    it "creates zero correctly (positive zero)" do
      word = described_class.from_i(0)
      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([0, 0, 0, 0, 0])
    end

    it "creates small positive numbers correctly" do
      word = described_class.from_i(1)
      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([0, 0, 0, 0, 1])

      word = described_class.from_i(63)
      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([0, 0, 0, 0, 63])
    end

    it "creates small negative numbers correctly" do
      word = described_class.from_i(-1)
      expect(word.sign).to eq(-1)
      expect(word.bytes).to eq([0, 0, 0, 0, 1])

      word = described_class.from_i(-63)
      expect(word.sign).to eq(-1)
      expect(word.bytes).to eq([0, 0, 0, 0, 63])
    end

    it "creates multi-byte numbers correctly" do
      # 64 = [0, 0, 0, 1, 0]
      word = described_class.from_i(64)
      expect(word.bytes).to eq([0, 0, 0, 1, 0])

      # 1000 = 15*64 + 40
      word = described_class.from_i(1000)
      expect(word.bytes).to eq([0, 0, 0, 15, 40])

      # 100000 = 24*64^2 + 26*64 + 32
      word = described_class.from_i(100_000)
      expect(word.bytes).to eq([0, 0, 24, 26, 32])
    end

    it "creates maximum value correctly" do
      word = described_class.from_i(described_class::MAX_VALUE)
      expect(word.bytes).to eq([63, 63, 63, 63, 63])
    end

    it "raises error for values exceeding capacity" do
      too_large = described_class::MAX_VALUE + 1
      expect { described_class.from_i(too_large) }.to raise_error(ArgumentError, /exceeds/)

      too_negative = -(described_class::MAX_VALUE + 1)
      expect { described_class.from_i(too_negative) }.to raise_error(ArgumentError, /exceeds/)
    end
  end

  describe "round-trip conversion" do
    it "round-trips positive numbers" do
      test_values = [0, 1, 63, 64, 100, 1000, 10_000, 100_000, 1_000_000, described_class::MAX_VALUE]
      test_values.each do |n|
        word = described_class.from_i(n)
        expect(word.to_i).to eq(n), "Failed for #{n}"
      end
    end

    it "round-trips negative numbers" do
      test_values = [-1, -63, -64, -100, -1000, -10_000, -100_000, -1_000_000, -described_class::MAX_VALUE]
      test_values.each do |n|
        word = described_class.from_i(n)
        expect(word.to_i).to eq(n), "Failed for #{n}"
      end
    end

    it "round-trips random values" do
      100.times do
        n = rand(-described_class::MAX_VALUE..described_class::MAX_VALUE)
        word = described_class.from_i(n)
        expect(word.to_i).to eq(n), "Failed for #{n}"
      end
    end
  end

  describe "#slice" do
    it "extracts sign only with (0:0)" do
      word = described_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
      slice = word.slice(0, 0)

      expect(slice.sign).to eq(-1)
      expect(slice.bytes).to eq([0, 0, 0, 0, 0])
    end

    it "extracts whole word with (0:5)" do
      word = described_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
      slice = word.slice(0, 5)

      expect(slice.sign).to eq(-1)
      expect(slice.bytes).to eq([1, 2, 3, 4, 5])
      expect(slice).to eq(word)
    end

    it "extracts bytes without sign with (1:5)" do
      word = described_class.new(sign: -1, bytes: [1, 2, 3, 4, 5])
      slice = word.slice(1, 5)

      expect(slice.sign).to eq(1)  # Positive when L > 0
      expect(slice.bytes).to eq([1, 2, 3, 4, 5])
    end

    it "extracts single byte with (1:1)" do
      word = described_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])
      slice = word.slice(1, 1)

      expect(slice.sign).to eq(1)
      expect(slice.bytes).to eq([0, 0, 0, 0, 10])
    end

    it "extracts byte range (2:4)" do
      word = described_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])
      slice = word.slice(2, 4)

      expect(slice.sign).to eq(1)
      # Bytes 2, 3, 4 -> right-aligned
      expect(slice.bytes).to eq([0, 0, 20, 30, 40])
    end

    it "extracts byte range (3:5)" do
      word = described_class.new(sign: 1, bytes: [10, 20, 30, 40, 50])
      slice = word.slice(3, 5)

      expect(slice.sign).to eq(1)
      # Bytes 3, 4, 5 -> right-aligned
      expect(slice.bytes).to eq([0, 0, 30, 40, 50])
    end

    it "validates field specifications" do
      word = described_class.new

      expect { word.slice(-1, 5) }.to raise_error(ArgumentError, /Left field spec/)
      expect { word.slice(0, 6) }.to raise_error(ArgumentError, /Right field spec/)
      expect { word.slice(3, 2) }.to raise_error(ArgumentError, /Left must be <= right/)
    end
  end

  describe "#store_slice!" do
    it "stores sign only with (0:0)" do
      word = described_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
      source = described_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

      word.store_slice!(0, 0, source)

      expect(word.sign).to eq(-1)
      expect(word.bytes).to eq([1, 2, 3, 4, 5])  # Bytes unchanged
    end

    it "stores whole word with (0:5)" do
      word = described_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
      source = described_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

      word.store_slice!(0, 5, source)

      expect(word.sign).to eq(-1)
      expect(word.bytes).to eq([10, 20, 30, 40, 50])
    end

    it "stores bytes without sign with (1:5)" do
      word = described_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
      source = described_class.new(sign: -1, bytes: [10, 20, 30, 40, 50])

      word.store_slice!(1, 5, source)

      expect(word.sign).to eq(1)  # Sign unchanged
      expect(word.bytes).to eq([10, 20, 30, 40, 50])
    end

    it "stores single byte with (5:5)" do
      word = described_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
      source = described_class.new(sign: -1, bytes: [0, 0, 0, 0, 63])

      word.store_slice!(5, 5, source)

      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([1, 2, 3, 4, 63])
    end

    it "stores byte range (2:4)" do
      word = described_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
      # Source has values in last 3 bytes
      source = described_class.new(sign: -1, bytes: [0, 0, 11, 22, 33])

      word.store_slice!(2, 4, source)

      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([1, 11, 22, 33, 5])
    end

    it "stores byte range (1:3)" do
      word = described_class.new(sign: 1, bytes: [1, 2, 3, 4, 5])
      source = described_class.new(sign: -1, bytes: [0, 0, 10, 20, 30])

      word.store_slice!(1, 3, source)

      expect(word.sign).to eq(1)
      expect(word.bytes).to eq([10, 20, 30, 4, 5])
    end

    it "validates field specifications" do
      word = described_class.new
      source = described_class.new

      expect { word.store_slice!(-1, 5, source) }.to raise_error(ArgumentError, /Left field spec/)
      expect { word.store_slice!(0, 6, source) }.to raise_error(ArgumentError, /Right field spec/)
      expect { word.store_slice!(3, 2, source) }.to raise_error(ArgumentError, /Left must be <= right/)
    end

    it "validates source is a Word" do
      word = described_class.new
      expect { word.store_slice!(0, 5, 42) }.to raise_error(ArgumentError, /Source must be a Word/)
    end

    it "returns self for chaining" do
      word = described_class.new
      source = described_class.new
      result = word.store_slice!(0, 5, source)
      expect(result).to be(word)
    end
  end

  describe ".encode_field_spec and .decode_field_spec" do
    it "encodes field spec (L:R) to byte F = 8*L + R" do
      expect(described_class.encode_field_spec(0, 5)).to eq(5)
      expect(described_class.encode_field_spec(1, 5)).to eq(13)
      expect(described_class.encode_field_spec(0, 0)).to eq(0)
      expect(described_class.encode_field_spec(3, 5)).to eq(29)
    end

    it "decodes field spec byte to (L, R)" do
      expect(described_class.decode_field_spec(5)).to eq([0, 5])
      expect(described_class.decode_field_spec(13)).to eq([1, 5])
      expect(described_class.decode_field_spec(0)).to eq([0, 0])
      expect(described_class.decode_field_spec(29)).to eq([3, 5])
    end

    it "round-trips encoding and decoding" do
      (0..5).each do |l|
        (l..5).each do |r|
          encoded = described_class.encode_field_spec(l, r)
          decoded = described_class.decode_field_spec(encoded)
          expect(decoded).to eq([l, r])
        end
      end
    end
  end

  describe "#==" do
    it "compares words correctly" do
      word1 = described_class.new(sign: 1, bytes: [0, 0, 0, 0, 5])
      word2 = described_class.new(sign: 1, bytes: [0, 0, 0, 0, 5])
      word3 = described_class.new(sign: -1, bytes: [0, 0, 0, 0, 5])

      expect(word1).to eq(word2)
      expect(word1).not_to eq(word3)
    end

    it "distinguishes +0 from -0" do
      positive_zero = described_class.new(sign: 1, bytes: [0, 0, 0, 0, 0])
      negative_zero = described_class.new(sign: -1, bytes: [0, 0, 0, 0, 0])

      expect(positive_zero).not_to eq(negative_zero)
    end
  end

  describe ".from_alf" do
    it "creates a word from a 5-character string" do
      word = described_class.from_alf("HELLO")
      # H=8, E=5, L=12, L=12, O=15
      expect(word.bytes).to eq([8, 5, 12, 12, 15])
      expect(word.sign).to eq(1)
    end

    it "pads short strings with spaces" do
      word = described_class.from_alf("HI")
      # H=8, I=9, then 3 spaces
      expect(word.bytes).to eq([8, 9, 0, 0, 0])
    end

    it "handles single characters" do
      word = described_class.from_alf("A")
      expect(word.bytes).to eq([1, 0, 0, 0, 0])
    end

    it "handles empty string" do
      word = described_class.from_alf("")
      expect(word.bytes).to eq([0, 0, 0, 0, 0])
    end

    it "raises error for strings longer than 5 characters" do
      expect { described_class.from_alf("TOOLONG") }.to raise_error(ArgumentError, /too long/)
    end

    it "is case-insensitive" do
      word1 = described_class.from_alf("HELLO")
      word2 = described_class.from_alf("hello")
      expect(word1).to eq(word2)
    end
  end

  describe "#to_alf" do
    it "converts a word to ALF string" do
      word = described_class.new(sign: 1, bytes: [8, 5, 12, 12, 15])
      expect(word.to_alf).to eq("HELLO")
    end

    it "converts spaces correctly" do
      word = described_class.new(sign: 1, bytes: [8, 9, 0, 0, 0])
      expect(word.to_alf).to eq("HI   ")
    end

    it "converts all spaces to space string" do
      word = described_class.new(sign: 1, bytes: [0, 0, 0, 0, 0])
      expect(word.to_alf).to eq("     ")
    end

    it "ignores sign (ALF is always character data)" do
      word = described_class.new(sign: -1, bytes: [8, 5, 12, 12, 15])
      expect(word.to_alf).to eq("HELLO")
    end
  end

  describe "ALF round-trip conversion" do
    it "round-trips 5-character strings" do
      ["HELLO", "WORLD", "MIX01", "12345", "A B C"].each do |str|
        word = described_class.from_alf(str)
        result = word.to_alf
        expect(result).to eq(str.upcase)
      end
    end

    it "round-trips short strings (with padding)" do
      word = described_class.from_alf("HI")
      expect(word.to_alf).to eq("HI   ")
    end
  end
end
