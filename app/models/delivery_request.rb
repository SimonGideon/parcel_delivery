class DeliveryRequest < ApplicationRecord
  belongs_to :user
  belongs_to :driver, optional: true
  belongs_to :pickup_address, class_name: "Address"
  belongs_to :delivery_address, class_name: "Address"
  has_many :delivery_events, -> { order(occurred_at: :asc) }, dependent: :destroy

  enum :status, {
    pending: 0,
    finding_driver: 1,
    assigned: 2,
    accepted: 3,
    rejected: 4,
    picked_up: 5,
    in_transit: 6,
    delivered: 7,
    cancelled: 8
  }, default: :pending

  validates :package_description, presence: true
  validates :package_weight, presence: true, numericality: { greater_than: 0 }

  # Records a DeliveryEvent and broadcasts an ActiveSupport::Notifications event so
  # downstream concerns (background jobs, future notifications) stay decoupled from
  # the model that owns the lifecycle state.
  def record_event!(event_type, metadata = {})
    event = delivery_events.create!(event_type: event_type, metadata: metadata, occurred_at: Time.current)
    ActiveSupport::Notifications.instrument("delivery_request.#{event_type}", delivery_request_id: id, metadata: metadata)
    event
  end
end
