# frozen_string_literal: true

module Quackers
  module Mixal
    class Error < StandardError; end
  end
end

require_relative "mixal/lexer"
require_relative "mixal/parser"
require_relative "mixal/symbol_table"
require_relative "mixal/assembler"
