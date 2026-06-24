require "rails_helper"

RSpec.describe DriverLocation, type: :model do
  it "is valid with a driver, latitude, and longitude" do
    expect(build(:driver_location)).to be_valid
  end

  it "rejects latitude out of range" do
    expect(build(:driver_location, latitude: -91)).not_to be_valid
  end

  it "rejects longitude out of range" do
    expect(build(:driver_location, longitude: -181)).not_to be_valid
  end

  it "defaults recorded_at to now when not given" do
    location = build(:driver_location, recorded_at: nil)
    expect { location.valid? }.to change(location, :recorded_at).from(nil)
  end

  describe "#coordinates" do
    it "returns [latitude, longitude] as floats" do
      location = build(:driver_location, latitude: "1.5", longitude: "36.5")
      expect(location.coordinates).to eq([1.5, 36.5])
    end
  end
end
