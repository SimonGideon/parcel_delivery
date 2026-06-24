require "rails_helper"

RSpec.describe Geo::Haversine do
  describe ".distance_km" do
    it "returns 0 for identical coordinates" do
      expect(described_class.distance_km([1.0, 36.0], [1.0, 36.0])).to eq(0)
    end

    it "returns the known great-circle distance between two real cities" do
      # Nairobi to Mombasa is approximately 440km.
      nairobi = [-1.2921, 36.8219]
      mombasa = [-4.0435, 39.6682]

      expect(described_class.distance_km(nairobi, mombasa)).to be_within(15).of(440)
    end

    it "returns a larger distance for farther points" do
      origin = [0.0, 0.0]
      near = [0.1, 0.1]
      far = [10.0, 10.0]

      expect(described_class.distance_km(origin, far)).to be > described_class.distance_km(origin, near)
    end
  end
end
