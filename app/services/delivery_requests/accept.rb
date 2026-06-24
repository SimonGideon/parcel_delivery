module DeliveryRequests
  class Accept
    def initialize(delivery_request:, driver:)
      @delivery_request = delivery_request
      @driver = driver
    end

    def call
      unless delivery_request.driver_id == driver.id
        raise TransitionError, "Delivery request is not assigned to this driver"
      end
      unless delivery_request.assigned?
        raise TransitionError, "Delivery request cannot be accepted from status '#{delivery_request.status}'"
      end

      ActiveRecord::Base.transaction do
        delivery_request.update!(status: :accepted)
        driver.update!(status: :on_delivery)
        delivery_request.record_event!(:driver_accepted, driver_id: driver.id)
      end

      delivery_request
    end

    private

    attr_reader :delivery_request, :driver
  end
end
