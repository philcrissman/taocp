# frozen_string_literal: true

require_relative "mix/word"
require_relative "mix/character"
require_relative "mix/instruction"
require_relative "mix/registers"
require_relative "mix/memory"
require_relative "mix/machine"

module Taocp
  module Mix
    class Error < StandardError; end
  end
end
