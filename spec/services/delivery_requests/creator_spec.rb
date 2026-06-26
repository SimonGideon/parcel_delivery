require "rails_helper"

RSpec.describe DeliveryRequests::Creator do
  let(:user) { create(:user) }
  let(:pickup_attrs) { { line1: "123 Main St", city: "Nairobi", latitude: 1.2945, longitude: 36.8228 } }
  let(:delivery_attrs) { { line1: "456 Side St", city: "Nairobi", latitude: 1.3, longitude: 36.83 } }

  def build_creator
    described_class.new(
      user: user,
      pickup_address_attrs: pickup_attrs,
      delivery_address_attrs: delivery_attrs,
      package_description: "Books",
      package_weight: 2.5
    )
  end

  it "persists the delivery request with pending status" do
    delivery_request = build_creator.call

    expect(delivery_request).to be_persisted
    expect(delivery_request.status).to eq("pending")
    expect(delivery_request.user).to eq(user)
  end

  it "stores distinct pickup and delivery address snapshots on the request" do
    delivery_request = build_creator.call

    expect(delivery_request.pickup_address.city).to eq("Nairobi")
    expect(delivery_request.delivery_address.line1).to eq("456 Side St")
    expect(delivery_request[:pickup_address]).not_to eq(delivery_request[:delivery_address])
  end

  it "records a created DeliveryEvent" do
    delivery_request = build_creator.call

    expect(delivery_request.delivery_events.pluck(:event_type)).to eq(["created"])
  end

  it "enqueues nearest-driver assignment via the created event" do
    expect { build_creator.call }.to have_enqueued_job(AssignNearestDriverJob)
  end

  it "rolls back everything if the delivery request is invalid" do
    creator = described_class.new(
      user: user,
      pickup_address_attrs: pickup_attrs,
      delivery_address_attrs: delivery_attrs,
      package_description: nil,
      package_weight: 2.5
    )

    expect { creator.call }.to raise_error(ActiveRecord::RecordInvalid)
    expect(DeliveryRequest.count).to eq(0)
  end
end
