require "rails_helper"

RSpec.describe DeliveryRequests::DriverDecision do
  let(:driver) { create(:driver, status: :available) }
  let(:delivery_request) { create(:delivery_request, driver: driver, status: :assigned) }

  it "accepts an assigned request and sets the driver to on_delivery" do
    result = described_class.new(delivery_request: delivery_request, driver: driver, decision: :accept).call

    expect(result.status).to eq("accepted")
    expect(driver.reload.status).to eq("on_delivery")
    expect(delivery_request.delivery_events.pluck(:event_type)).to include("driver_accepted")
  end

  it "rejects an assigned request, clears the driver, and enqueues reassignment" do
    expect {
      result = described_class.new(delivery_request: delivery_request, driver: driver, decision: :reject).call

      expect(result.status).to eq("finding_driver")
      expect(result.driver).to be_nil
    }.to have_enqueued_job(AssignNearestDriverJob)

    event = delivery_request.delivery_events.find_by(event_type: :driver_rejected)
    expect(event.metadata["driver_id"]).to eq(driver.id)
  end

  it "raises TransitionError when the driver is not the assigned driver" do
    other_driver = create(:driver)

    expect {
      described_class.new(delivery_request: delivery_request, driver: other_driver, decision: :accept).call
    }.to raise_error(DeliveryRequests::TransitionError, /not assigned/)
  end

  it "raises TransitionError when the request is not in assigned status" do
    delivery_request.update!(status: :accepted)

    expect {
      described_class.new(delivery_request: delivery_request, driver: driver, decision: :reject).call
    }.to raise_error(DeliveryRequests::TransitionError)
  end
end
