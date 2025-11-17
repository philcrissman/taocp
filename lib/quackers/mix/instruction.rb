# frozen_string_literal: true

module Quackers
  module Mix
    # Represents a MIX instruction
    # Format: ± AA II F C
    #   AA = address (2 bytes)
    #   II = index (1 byte)
    #   F  = field specification (1 byte)
    #   C  = operation code (1 byte)
    class Instruction
      attr_reader :address, :index, :field, :opcode, :sign

      def initialize(address: 0, index: 0, field: 0, opcode: 0, sign: 1)
        @address = address
        @index = index
        @field = field
        @opcode = opcode
        @sign = sign
      end

      def inspect
        sign_str = @sign >= 0 ? "+" : "-"
        "#<Mix::Instruction #{sign_str}#{@address},#{@index}(#{@field}) C=#{@opcode}>"
      end
    end
  end
end
