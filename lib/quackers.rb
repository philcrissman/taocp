require_relative "quackers/version"
require_relative "quackers/mix"
require_relative "quackers/mixal"

module Quackers
  class Error < StandardError; end

  # Your code goes here...
  def self.quack
    "Quack! Quack!"
  end
end
