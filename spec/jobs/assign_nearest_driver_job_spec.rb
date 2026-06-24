require "rails_helper"

RSpec.describe AssignNearestDriverJob, type: :job do
  it "assigns the nearest available driver to the delivery request" do
    pickup_address = create(:address, latitude: 1.2945, longitude: 36.8228)
    delivery_request = create(:delivery_request, pickup_address: pickup_address, status: :pending)
    driver = create(:driver, status: :available)
    create(:driver_location, driver: driver, latitude: 1.2946, longitude: 36.8229)

    described_class.perform_now(delivery_request.id)

    expect(delivery_request.reload.driver).to eq(driver)
    expect(delivery_request.status).to eq("assigned")
  end

  it "does nothing if the delivery request no longer exists" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
