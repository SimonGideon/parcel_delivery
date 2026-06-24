module DeliveryRequests
  # Rejecting puts the request back into finding_driver so AssignDriver can be
  # retried (excluding this driver) -- driven by the driver_rejected notification,
  # not called directly here, to keep this service focused on the rejection itself.
  class Reject
    def initialize(delivery_request:, driver:)
      @delivery_request = delivery_request
      @driver = driver
    end

    def call
      unless delivery_request.driver_id == driver.id
        raise TransitionError, "Delivery request is not assigned to this driver"
      end
      unless delivery_request.assigned?
        raise TransitionError, "Delivery request cannot be rejected from status '#{delivery_request.status}'"
      end

      ActiveRecord::Base.transaction do
        delivery_request.record_event!(:driver_rejected, driver_id: driver.id)
        delivery_request.update!(driver: nil, status: :finding_driver)
      end

      delivery_request
    end

    private

    attr_reader :delivery_request, :driver
  end
end
