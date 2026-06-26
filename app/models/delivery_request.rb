class DeliveryRequest < ApplicationRecord
  belongs_to :user
  belongs_to :driver, class_name: "Driver", optional: true
  has_many :delivery_events, -> { order(occurred_at: :asc) }, dependent: :destroy

  # "rejected" is intentionally not a status here: a driver rejection sends the
  # request straight back to finding_driver for the next candidate. The rejection
  # itself is recorded as a DeliveryEvent (driver_rejected), not a request status.
  enum :status, {
    pending: 0,
    finding_driver: 1,
    assigned: 2,
    accepted: 3,
    picked_up: 5,
    in_transit: 6,
    delivered: 7,
    cancelled: 8
  }, default: :pending

  validates :package_description, presence: true
  validates :package_weight, presence: true, numericality: { greater_than: 0 }
  validate :addresses_are_valid

  def pickup_address
    DeliveryRequestAddress.from(self[:pickup_address])
  end

  def pickup_address=(value)
    self[:pickup_address] = DeliveryRequestAddress.from(value).to_h
  end

  def delivery_address
    DeliveryRequestAddress.from(self[:delivery_address])
  end

  def delivery_address=(value)
    self[:delivery_address] = DeliveryRequestAddress.from(value).to_h
  end

  def country
    nil
  end

  def county
    nil
  end

  # Records a DeliveryEvent and broadcasts an ActiveSupport::Notifications event so
  # downstream concerns (background jobs, future notifications) stay decoupled from
  # the model that owns the lifecycle state.
  def record_event!(event_type, metadata = {})
    event = delivery_events.create!(event_type: event_type, metadata: metadata, occurred_at: Time.current)
    ActiveSupport::Notifications.instrument("delivery_request.#{event_type}", delivery_request_id: id, metadata: metadata)
    event
  end

  private

  def addresses_are_valid
    validate_address(:pickup_address, pickup_address)
    validate_address(:delivery_address, delivery_address)
  end

  def validate_address(_attribute, address)
    return if address.valid?

    address.errors.each do |error|
      errors.add(error.attribute, error.type, **error.options)
    end
  end
end
