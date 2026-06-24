require "rails_helper"

RSpec.describe DeliveryRequests::AssignDriver do
  let(:pickup_address) { create(:address, latitude: 1.2945, longitude: 36.8228) }
  let(:delivery_request) { create(:delivery_request, pickup_address: pickup_address, status: :pending) }

  it "assigns the nearest available driver and records driver_assigned" do
    driver = create(:driver, status: :available)
    create(:driver_location, driver: driver, latitude: 1.2946, longitude: 36.8229)

    result = described_class.new(delivery_request).call

    expect(result.status).to eq("assigned")
    expect(result.driver).to eq(driver)
    expect(result.delivery_events.pluck(:event_type)).to include("driver_assigned")
  end

  it "moves a pending request to finding_driver even when no driver is found" do
    result = described_class.new(delivery_request).call

    expect(result.status).to eq("finding_driver")
    expect(result.driver).to be_nil
    expect(result.delivery_events.pluck(:event_type)).to include("finding_driver")
  end

  it "excludes drivers who already rejected this request" do
    rejecter = create(:driver, status: :available)
    create(:driver_location, driver: rejecter, latitude: 1.2946, longitude: 36.8229)
    delivery_request.record_event!(:driver_rejected, driver_id: rejecter.id)

    farther = create(:driver, status: :available)
    create(:driver_location, driver: farther, latitude: 1.5, longitude: 37.0)

    result = described_class.new(delivery_request).call

    expect(result.driver).to eq(farther)
  end
end
