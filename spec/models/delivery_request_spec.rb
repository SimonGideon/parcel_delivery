require "rails_helper"

RSpec.describe DeliveryRequest, type: :model do
  it "is valid with a user, addresses, description, and weight" do
    expect(build(:delivery_request)).to be_valid
  end

  it "does not require a driver" do
    expect(build(:delivery_request, driver: nil)).to be_valid
  end

  it "requires a package_description" do
    expect(build(:delivery_request, package_description: nil)).not_to be_valid
  end

  it "requires a positive package_weight" do
    expect(build(:delivery_request, package_weight: 0)).not_to be_valid
    expect(build(:delivery_request, package_weight: -1)).not_to be_valid
  end

  it "defaults to pending status" do
    expect(create(:delivery_request).status).to eq("pending")
  end

  it "does not define a rejected status (rejections are events, not request statuses)" do
    expect(DeliveryRequest.statuses.keys).not_to include("rejected")
  end

  describe "#record_event!" do
    it "creates a DeliveryEvent with the given type and metadata" do
      delivery_request = create(:delivery_request)

      expect {
        delivery_request.record_event!(:driver_assigned, driver_id: 42)
      }.to change(delivery_request.delivery_events, :count).by(1)

      event = delivery_request.delivery_events.last
      expect(event.event_type).to eq("driver_assigned")
      expect(event.metadata["driver_id"]).to eq(42)
    end

    it "instruments an ActiveSupport::Notifications event" do
      delivery_request = create(:delivery_request)
      payload = nil
      callback = ->(*args) { payload = ActiveSupport::Notifications::Event.new(*args).payload }

      ActiveSupport::Notifications.subscribed(callback, "delivery_request.created") do
        delivery_request.record_event!(:created)
      end

      expect(payload).to include(delivery_request_id: delivery_request.id)
    end
  end
end
