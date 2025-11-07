RSpec.describe Quackers do
  it "has a version number" do
    expect(Quackers::VERSION).not_to be nil
  end

  it "quacks" do
    expect(Quackers.quack).to eq("Quack! Quack!")
  end
end
