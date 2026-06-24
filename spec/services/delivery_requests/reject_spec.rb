require "rails_helper"

RSpec.describe DeliveryRequests::Reject do
  let(:driver) { create(:driver, status: :available) }
  let(:delivery_request) { create(:delivery_request, driver: driver, status: :assigned) }

  it "clears the driver and returns the request to finding_driver" do
    result = described_class.new(delivery_request: delivery_request, driver: driver).call

    expect(result.status).to eq("finding_driver")
    expect(result.driver).to be_nil
  end

  it "records a driver_rejected event with the driver's id" do
    described_class.new(delivery_request: delivery_request, driver: driver).call

    event = delivery_request.delivery_events.find_by(event_type: :driver_rejected)
    expect(event.metadata["driver_id"]).to eq(driver.id)
  end

  it "enqueues a re-search via the driver_rejected event" do
    expect {
      described_class.new(delivery_request: delivery_request, driver: driver).call
    }.to have_enqueued_job(AssignNearestDriverJob)
  end

  it "raises TransitionError when the driver is not the assigned driver" do
    other_driver = create(:driver)

    expect {
      described_class.new(delivery_request: delivery_request, driver: other_driver).call
    }.to raise_error(DeliveryRequests::TransitionError, /not assigned/)
  end

  it "raises TransitionError when the request is not in assigned status" do
    delivery_request.update!(status: :accepted)

    expect {
      described_class.new(delivery_request: delivery_request, driver: driver).call
    }.to raise_error(DeliveryRequests::TransitionError)
  end
end
