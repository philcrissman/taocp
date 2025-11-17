# frozen_string_literal: true

require_relative "mixal/lexer"
require_relative "mixal/parser"
require_relative "mixal/symbol_table"
require_relative "mixal/assembler"

module Quackers
  module Mixal
    class Error < StandardError; end
  end
end
