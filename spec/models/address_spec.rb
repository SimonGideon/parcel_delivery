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

  it "does not require a country or county" do
    expect(build(:address, country: nil, county: nil)).to be_valid
  end

  it "allows the optional receiving-details fields to be blank" do
    address = build(:address, building_name: nil, floor: nil, door: nil, instructions: nil)
    expect(address).to be_valid
  end

  it "accepts receiving-details for whoever is physically receiving the delivery" do
    address = build(:address, building_name: "ABC Place", floor: "3rd floor", door: "B12", instructions: "Call at the gate")
    expect(address).to be_valid
  end

  it "rejects a county that belongs to a different country than the selected country" do
    kenya = create(:country, :kenya)
    other_country = create(:country)
    mismatched_county = create(:county, country: other_country)

    address = build(:address, country: kenya, county: mismatched_county)

    expect(address).not_to be_valid
    expect(address.errors[:county]).to be_present
  end

  it "rejects a county_id that does not refer to an existing county" do
    address = build(:address, county_id: SecureRandom.uuid, country: nil)

    expect(address).not_to be_valid
    expect(address.errors[:county]).to include("must exist")
  end

  it "rejects a country_id that does not refer to an existing country" do
    address = build(:address, country_id: SecureRandom.uuid, county: nil)

    expect(address).not_to be_valid
    expect(address.errors[:country]).to include("must exist")
  end
end
