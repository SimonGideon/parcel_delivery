require "rails_helper"

RSpec.describe DeliveryRequests::Accept do
  let(:driver) { create(:driver, status: :available) }
  let(:delivery_request) { create(:delivery_request, driver: driver, status: :assigned) }

  it "transitions the request to accepted and the driver to on_delivery" do
    result = described_class.new(delivery_request: delivery_request, driver: driver).call

    expect(result.status).to eq("accepted")
    expect(driver.reload.status).to eq("on_delivery")
  end

  it "records a driver_accepted event" do
    described_class.new(delivery_request: delivery_request, driver: driver).call

    expect(delivery_request.delivery_events.pluck(:event_type)).to include("driver_accepted")
  end

  it "raises TransitionError when the driver is not the assigned driver" do
    other_driver = create(:driver)

    expect {
      described_class.new(delivery_request: delivery_request, driver: other_driver).call
    }.to raise_error(DeliveryRequests::TransitionError, /not assigned/)
  end

  it "raises TransitionError when the request is not in assigned status" do
    delivery_request.update!(status: :pending, driver: nil)

    expect {
      described_class.new(delivery_request: delivery_request, driver: driver).call
    }.to raise_error(DeliveryRequests::TransitionError)
  end
end
