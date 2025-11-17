# frozen_string_literal: true

module Quackers
  module Mix
    # Represents a MIX word: sign + 5 bytes (each 0..63)
    # Sign is +1 or -1
    # Bytes are numbered 1..5 (byte 0 is the sign)
    #
    # MIX uses base-64 arithmetic for bytes.
    # Maximum positive value: 64^5 - 1 = 1,073,741,823
    class Word
      BYTE_SIZE = 64
      NUM_BYTES = 5
      MAX_VALUE = (BYTE_SIZE ** NUM_BYTES) - 1

      attr_reader :sign, :bytes

      def initialize(sign: 1, bytes: [0, 0, 0, 0, 0])
        raise ArgumentError, "Sign must be +1 or -1" unless [1, -1].include?(sign)
        raise ArgumentError, "Must have exactly 5 bytes" unless bytes.length == NUM_BYTES

        bytes.each_with_index do |b, i|
          unless b >= 0 && b < BYTE_SIZE
            raise ArgumentError, "Byte #{i + 1} must be 0..63, got #{b}"
          end
        end

        @sign = sign
        @bytes = bytes.dup
      end

      # Convert MIX word to integer
      # Uses base-64 positional notation
      def to_i
        magnitude = 0
        power = 1

        # Process bytes from right to left (byte 5 to byte 1)
        (NUM_BYTES - 1).downto(0) do |i|
          magnitude += @bytes[i] * power
          power *= BYTE_SIZE
        end

        @sign * magnitude
      end

      # Create MIX word from integer
      def self.from_i(value)
        # Handle zero specially (positive zero in MIX)
        return new(sign: 1, bytes: [0, 0, 0, 0, 0]) if value == 0

        # Extract sign and magnitude
        sign = value < 0 ? -1 : 1
        magnitude = value.abs

        # Check overflow
        if magnitude > MAX_VALUE
          raise ArgumentError, "Value #{value} exceeds MIX word capacity (max #{MAX_VALUE})"
        end

        # Convert magnitude to base-64 bytes
        bytes = []
        NUM_BYTES.times do
          bytes.unshift(magnitude % BYTE_SIZE)
          magnitude /= BYTE_SIZE
        end

        new(sign: sign, bytes: bytes)
      end

      # Extract a field (L:R) from this word
      # Returns a new Word containing only the specified field
      # If L = 0, includes the sign; otherwise result has positive sign
      # Bytes outside L..R are zero
      def slice(left, right)
        validate_field_spec!(left, right)

        # Extract sign
        new_sign = (left == 0) ? @sign : 1

        # Extract bytes
        new_bytes = [0, 0, 0, 0, 0]

        if right > 0
          # Determine which bytes to copy
          start_byte = [left, 1].max - 1  # Convert to 0-indexed (byte 1 -> index 0)
          end_byte = right - 1            # Convert to 0-indexed

          # Copy bytes, right-aligned in result
          num_bytes_to_copy = end_byte - start_byte + 1
          dest_start = NUM_BYTES - num_bytes_to_copy

          num_bytes_to_copy.times do |i|
            new_bytes[dest_start + i] = @bytes[start_byte + i]
          end
        end

        Word.new(sign: new_sign, bytes: new_bytes)
      end

      # Store a field from source into this word at position (L:R)
      # Modifies this word in place
      def store_slice!(left, right, source)
        validate_field_spec!(left, right)
        raise ArgumentError, "Source must be a Word" unless source.is_a?(Word)

        # Store sign if L = 0
        @sign = source.sign if left == 0

        # Store bytes if R > 0
        if right > 0
          # Determine which bytes to store
          start_byte = [left, 1].max - 1  # Convert to 0-indexed
          end_byte = right - 1

          # Source bytes are right-aligned, so we take from the right end
          num_bytes_to_store = end_byte - start_byte + 1
          source_start = NUM_BYTES - num_bytes_to_store

          num_bytes_to_store.times do |i|
            @bytes[start_byte + i] = source.bytes[source_start + i]
          end
        end

        self
      end

      # Convert field spec (L, R) to single byte value F = 8*L + R
      def self.encode_field_spec(left, right)
        8 * left + right
      end

      # Convert field spec byte F to (L, R)
      def self.decode_field_spec(field)
        [field / 8, field % 8]
      end

      # Create a Word from an ALF string (up to 5 characters)
      # ALF = "alphabetic" data in MIXAL
      def self.from_alf(str)
        raise ArgumentError, "ALF string too long (max 5 chars)" if str.length > 5

        codes = Character.string_to_codes(str)
        # Pad to 5 characters with spaces if needed
        codes += [0] * (5 - codes.length) if codes.length < 5

        new(sign: 1, bytes: codes)
      end

      # Convert this Word to an ALF string
      def to_alf
        Character.codes_to_string(@bytes)
      end

      # Equality comparison
      def ==(other)
        return false unless other.is_a?(Word)
        # Note: +0 and -0 are different in MIX
        @sign == other.sign && @bytes == other.bytes
      end

      def inspect
        sign_str = @sign >= 0 ? "+" : "-"
        bytes_str = @bytes.map { |b| "%02d" % b }.join(" ")
        "#<Mix::Word #{sign_str} #{bytes_str} (#{to_i})>"
      end

      private

      def validate_field_spec!(left, right)
        unless left >= 0 && left <= NUM_BYTES
          raise ArgumentError, "Left field spec must be 0..5, got #{left}"
        end
        unless right >= 0 && right <= NUM_BYTES
          raise ArgumentError, "Right field spec must be 0..5, got #{right}"
        end
        unless left <= right
          raise ArgumentError, "Left must be <= right (#{left}:#{right})"
        end
      end
    end
  end
end
