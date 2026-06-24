require "rails_helper"

RSpec.describe DeliveryEvent, type: :model do
  it "is valid with a delivery_request, event_type, and occurred_at" do
    expect(build(:delivery_event)).to be_valid
  end

  it "requires occurred_at" do
    expect(build(:delivery_event, occurred_at: nil)).not_to be_valid
  end

  it "exposes the full lifecycle event_type enum" do
    expect(DeliveryEvent.event_types.keys).to contain_exactly(
      "created", "finding_driver", "driver_assigned", "driver_accepted",
      "driver_rejected", "picked_up", "in_transit", "delivered", "cancelled"
    )
  end

  it "orders by occurred_at ascending through the delivery_request association" do
    delivery_request = create(:delivery_request)
    later = create(:delivery_event, delivery_request: delivery_request, occurred_at: 1.minute.ago)
    earlier = create(:delivery_event, delivery_request: delivery_request, occurred_at: 1.hour.ago)

    expect(delivery_request.delivery_events).to eq([earlier, later])
  end
end
