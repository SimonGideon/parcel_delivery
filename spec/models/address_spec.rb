require "rails_helper"

RSpec.describe Address, type: :model do
  it "is valid with a line1, city, latitude, and longitude" do
    expect(build(:address)).to be_valid
  end

  it "requires line1" do
    expect(build(:address, line1: nil)).not_to be_valid
  end

  it "requires city" do
    expect(build(:address, city: nil)).not_to be_valid
  end

  it "rejects latitude out of range" do
    expect(build(:address, latitude: 91)).not_to be_valid
  end

  it "rejects longitude out of range" do
    expect(build(:address, longitude: 181)).not_to be_valid
  end

  describe "#coordinates" do
    it "returns [latitude, longitude] as floats" do
      address = build(:address, latitude: "1.5", longitude: "36.5")
      expect(address.coordinates).to eq([1.5, 36.5])
    end
  end
end
