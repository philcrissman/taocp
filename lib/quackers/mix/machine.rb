# frozen_string_literal: true

module Quackers
  module Mix
    # The MIX virtual machine
    class Machine
      attr_reader :memory, :registers, :pc
      attr_accessor :halted

      def initialize
        @memory = Memory.new
        @registers = Registers.new
        @pc = 0  # Program counter
        @halted = false
      end

      def run
        # TODO: Implement in Step 7
        raise Error, "VM execution not yet implemented"
      end

      def step
        # TODO: Implement in Step 7
        raise Error, "Single-step execution not yet implemented"
      end

      def reset
        @memory = Memory.new
        @registers = Registers.new
        @pc = 0
        @halted = false
      end
    end
  end
end
