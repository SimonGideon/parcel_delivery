module DeliveryRequests
  class Cancel
    CANCELLABLE_STATUSES = %w[pending finding_driver assigned accepted].freeze

    def initialize(delivery_request:, user:)
      @delivery_request = delivery_request
      @user = user
    end

    def call
      unless delivery_request.user_id == user.id
        raise TransitionError, "Delivery request does not belong to this user"
      end
      unless CANCELLABLE_STATUSES.include?(delivery_request.status)
        raise TransitionError, "Delivery request cannot be cancelled from status '#{delivery_request.status}'"
      end

      ActiveRecord::Base.transaction do
        release_driver_if_needed
        delivery_request.record_event!(:cancelled, user_id: user.id, driver_id: delivery_request.driver_id)
        delivery_request.update!(driver: nil, status: :cancelled)
      end

      delivery_request
    end

    private

    attr_reader :delivery_request, :user

    def release_driver_if_needed
      driver = delivery_request.driver
      return unless driver&.on_delivery?

      driver.update!(status: :available)
    end
  end
end
