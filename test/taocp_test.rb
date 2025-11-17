require "test_helper"

class TaocpTest < Minitest::Test
  def test_has_a_version_number
    refute_nil Taocp::VERSION
  end
end
