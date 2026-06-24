module DeliveryRequests
  # Finds and assigns the nearest available driver to a delivery request,
  # excluding drivers who have already rejected this same request.
  class AssignDriver
    def initialize(delivery_request)
      @delivery_request = delivery_request
    end

    def call
      delivery_request.update!(status: :finding_driver) if delivery_request.pending?

      driver = Drivers::FindNearestAvailable.new(
        origin_coordinates: delivery_request.pickup_address.coordinates,
        exclude_driver_ids: previously_rejected_driver_ids
      ).call

      if driver
        delivery_request.update!(driver: driver, status: :assigned)
        delivery_request.record_event!(:driver_assigned, driver_id: driver.id)
      else
        delivery_request.record_event!(:finding_driver, reason: "no_available_driver")
      end

      delivery_request
    end

    private

    attr_reader :delivery_request

    def previously_rejected_driver_ids
      delivery_request.delivery_events.driver_rejected.filter_map { |event| event.metadata["driver_id"] }
    end
  end
end
