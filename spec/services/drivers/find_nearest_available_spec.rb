require "rails_helper"

RSpec.describe Drivers::FindNearestAvailable do
  let(:origin) { [1.2945, 36.8228] }

  it "returns nil when there are no available drivers" do
    result = described_class.new(origin_coordinates: origin).call
    expect(result).to be_nil
  end

  it "returns nil when available drivers have no recorded location" do
    create(:driver, status: :available)

    result = described_class.new(origin_coordinates: origin).call
    expect(result).to be_nil
  end

  it "ignores unavailable and on_delivery drivers" do
    busy = create(:driver, status: :on_delivery)
    create(:driver_location, driver: busy, latitude: 1.2945, longitude: 36.8228)
    unavailable = create(:driver, status: :unavailable)
    create(:driver_location, driver: unavailable, latitude: 1.2945, longitude: 36.8228)

    result = described_class.new(origin_coordinates: origin).call
    expect(result).to be_nil
  end

  it "returns the closest available driver by latest known location" do
    near = create(:driver, status: :available)
    create(:driver_location, driver: near, latitude: 1.2946, longitude: 36.8229)

    far = create(:driver, status: :available)
    create(:driver_location, driver: far, latitude: 1.5, longitude: 37.0)

    result = described_class.new(origin_coordinates: origin).call
    expect(result).to eq(near)
  end

  it "uses each driver's most recent location, not an older one" do
    driver = create(:driver, status: :available)
    create(:driver_location, driver: driver, latitude: 10.0, longitude: 10.0, recorded_at: 1.hour.ago)
    create(:driver_location, driver: driver, latitude: 1.2946, longitude: 36.8229, recorded_at: 1.minute.ago)

    result = described_class.new(origin_coordinates: origin).call
    expect(result).to eq(driver)
  end

  it "excludes drivers in exclude_driver_ids" do
    near = create(:driver, status: :available)
    create(:driver_location, driver: near, latitude: 1.2946, longitude: 36.8229)

    far = create(:driver, status: :available)
    create(:driver_location, driver: far, latitude: 1.5, longitude: 37.0)

    result = described_class.new(origin_coordinates: origin, exclude_driver_ids: [near.id]).call
    expect(result).to eq(far)
  end
end
