# frozen_string_literal: true

RSpec.describe Taocp::Mixal::SymbolTable do
  let(:symbol_table) { Taocp::Mixal::SymbolTable.new }

  describe "symbol definition" do
    it "defines a symbol" do
      symbol_table.define("START", 1000)
      expect(symbol_table.lookup("START")).to eq(1000)
    end

    it "is case-insensitive" do
      symbol_table.define("start", 1000)
      expect(symbol_table.lookup("START")).to eq(1000)
      expect(symbol_table.lookup("Start")).to eq(1000)
    end

    it "raises error on duplicate definition" do
      symbol_table.define("LABEL", 100)
      expect {
        symbol_table.define("LABEL", 200)
      }.to raise_error(Taocp::Mixal::SymbolTable::Error, /already defined/)
    end

    it "checks if symbol is defined" do
      symbol_table.define("TEST", 500)
      expect(symbol_table.defined?("TEST")).to be true
      expect(symbol_table.defined?("UNDEFINED")).to be false
    end
  end

  describe "symbol lookup" do
    it "returns nil for undefined symbol" do
      expect(symbol_table.lookup("UNDEFINED")).to be_nil
    end

    it "returns defined value" do
      symbol_table.define("VALUE", 42)
      expect(symbol_table.lookup("VALUE")).to eq(42)
    end
  end

  describe "expression evaluation" do
    before do
      symbol_table.define("START", 1000)
      symbol_table.define("END", 2000)
      symbol_table.define("SIZE", 100)
    end

    it "evaluates integer directly" do
      expect(symbol_table.evaluate(500)).to eq(500)
    end

    it "evaluates string integer" do
      expect(symbol_table.evaluate("500")).to eq(500)
    end

    it "evaluates negative integer" do
      expect(symbol_table.evaluate("-50")).to eq(-50)
    end

    it "evaluates simple symbol" do
      expect(symbol_table.evaluate("START")).to eq(1000)
    end

    it "evaluates symbol + number" do
      expect(symbol_table.evaluate("START+10")).to eq(1010)
    end

    it "evaluates symbol - number" do
      expect(symbol_table.evaluate("END-5")).to eq(1995)
    end

    it "raises error for undefined symbol" do
      expect {
        symbol_table.evaluate("UNDEFINED")
      }.to raise_error(Taocp::Mixal::SymbolTable::Error, /Undefined symbol/)
    end

    it "raises error for undefined symbol in expression" do
      expect {
        symbol_table.evaluate("UNDEFINED+10")
      }.to raise_error(Taocp::Mixal::SymbolTable::Error, /Undefined symbol/)
    end
  end

  describe "current address evaluation" do
    before do
      symbol_table.define("LOOP", 500)
    end

    it "evaluates * as current location" do
      expect(symbol_table.evaluate_with_location("*", 100)).to eq(100)
    end

    it "evaluates *+N" do
      expect(symbol_table.evaluate_with_location("*+2", 100)).to eq(102)
    end

    it "evaluates *-N" do
      expect(symbol_table.evaluate_with_location("*-5", 100)).to eq(95)
    end

    it "evaluates symbol with location context" do
      expect(symbol_table.evaluate_with_location("LOOP", 100)).to eq(500)
    end

    it "evaluates symbol+N with location context" do
      expect(symbol_table.evaluate_with_location("LOOP+10", 100)).to eq(510)
    end
  end

  describe "all symbols" do
    it "returns all defined symbols" do
      symbol_table.define("A", 1)
      symbol_table.define("B", 2)
      symbol_table.define("C", 3)

      all = symbol_table.all
      expect(all["A"]).to eq(1)
      expect(all["B"]).to eq(2)
      expect(all["C"]).to eq(3)
    end

    it "returns a copy (not modifiable)" do
      symbol_table.define("TEST", 100)
      all = symbol_table.all
      all["TEST"] = 999

      expect(symbol_table.lookup("TEST")).to eq(100)
    end
  end
end
