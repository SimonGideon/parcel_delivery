class DeliveryEvent < ApplicationRecord
  belongs_to :delivery_request

  enum :event_type, {
    created: 0,
    finding_driver: 1,
    driver_assigned: 2,
    driver_accepted: 3,
    driver_rejected: 4,
    picked_up: 5,
    in_transit: 6,
    delivered: 7,
    cancelled: 8
  }

  validates :occurred_at, presence: true
end
