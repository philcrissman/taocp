# frozen_string_literal: true

require "test_helper"

class MixalSymbolTableTest < Minitest::Test
  def setup
    @symbol_table = Taocp::Mixal::SymbolTable.new
  end

  # Symbol definition tests
  def test_defines_a_symbol
    @symbol_table.define("START", 1000)
    assert_equal 1000, @symbol_table.lookup("START")
  end

  def test_is_case_insensitive
    @symbol_table.define("start", 1000)
    assert_equal 1000, @symbol_table.lookup("START")
    assert_equal 1000, @symbol_table.lookup("Start")
  end

  def test_raises_error_on_duplicate_definition
    @symbol_table.define("LABEL", 100)
    assert_raises(Taocp::Mixal::SymbolTable::Error, /already defined/) do
      @symbol_table.define("LABEL", 200)
    end
  end

  def test_checks_if_symbol_is_defined
    @symbol_table.define("TEST", 500)
    assert @symbol_table.defined?("TEST")
    refute @symbol_table.defined?("UNDEFINED")
  end

  # Symbol lookup tests
  def test_returns_nil_for_undefined_symbol
    assert_nil @symbol_table.lookup("UNDEFINED")
  end

  def test_returns_defined_value
    @symbol_table.define("VALUE", 42)
    assert_equal 42, @symbol_table.lookup("VALUE")
  end

  # Expression evaluation tests
  def test_evaluates_integer_directly
    @symbol_table.define("START", 1000)
    assert_equal 500, @symbol_table.evaluate(500)
  end

  def test_evaluates_string_integer
    assert_equal 500, @symbol_table.evaluate("500")
  end

  def test_evaluates_negative_integer
    assert_equal(-50, @symbol_table.evaluate("-50"))
  end

  def test_evaluates_simple_symbol
    @symbol_table.define("START", 1000)
    assert_equal 1000, @symbol_table.evaluate("START")
  end

  def test_evaluates_symbol_plus_number
    @symbol_table.define("START", 1000)
    assert_equal 1010, @symbol_table.evaluate("START+10")
  end

  def test_evaluates_symbol_minus_number
    @symbol_table.define("END", 2000)
    assert_equal 1995, @symbol_table.evaluate("END-5")
  end

  def test_raises_error_for_undefined_symbol
    assert_raises(Taocp::Mixal::SymbolTable::Error, /Undefined symbol/) do
      @symbol_table.evaluate("UNDEFINED")
    end
  end

  def test_raises_error_for_undefined_symbol_in_expression
    assert_raises(Taocp::Mixal::SymbolTable::Error, /Undefined symbol/) do
      @symbol_table.evaluate("UNDEFINED+10")
    end
  end

  # Current address evaluation tests
  def test_evaluates_asterisk_as_current_location
    assert_equal 100, @symbol_table.evaluate_with_location("*", 100)
  end

  def test_evaluates_asterisk_plus_n
    assert_equal 102, @symbol_table.evaluate_with_location("*+2", 100)
  end

  def test_evaluates_asterisk_minus_n
    assert_equal 95, @symbol_table.evaluate_with_location("*-5", 100)
  end

  def test_evaluates_symbol_with_location_context
    @symbol_table.define("LOOP", 500)
    assert_equal 500, @symbol_table.evaluate_with_location("LOOP", 100)
  end

  def test_evaluates_symbol_plus_n_with_location_context
    @symbol_table.define("LOOP", 500)
    assert_equal 510, @symbol_table.evaluate_with_location("LOOP+10", 100)
  end

  # All symbols tests
  def test_returns_all_defined_symbols
    @symbol_table.define("A", 1)
    @symbol_table.define("B", 2)
    @symbol_table.define("C", 3)

    all = @symbol_table.all
    assert_equal 1, all["A"]
    assert_equal 2, all["B"]
    assert_equal 3, all["C"]
  end

  def test_returns_a_copy_not_modifiable
    @symbol_table.define("TEST", 100)
    all = @symbol_table.all
    all["TEST"] = 999

    assert_equal 100, @symbol_table.lookup("TEST")
  end
end
