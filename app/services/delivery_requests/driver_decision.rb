module DeliveryRequests
  class DriverDecision
    DECISIONS = %i[accept reject].freeze

    def initialize(delivery_request:, driver:, decision:)
      @delivery_request = delivery_request
      @driver = driver
      @decision = decision.to_sym
    end

    def call
      validate_decision!
      validate_assignment!
      validate_status!

      ActiveRecord::Base.transaction do
        accept? ? accept_request : reject_request
      end

      delivery_request
    end

    private

    attr_reader :delivery_request, :driver, :decision

    def validate_decision!
      return if DECISIONS.include?(decision)

      raise ArgumentError, "unsupported driver decision: #{decision}"
    end

    def validate_assignment!
      return if delivery_request.driver_id == driver.id

      raise TransitionError, "Delivery request is not assigned to this driver"
    end

    def validate_status!
      return if delivery_request.assigned?

      raise TransitionError, "Delivery request cannot be #{decision_past_tense} from status '#{delivery_request.status}'"
    end

    def accept_request
      delivery_request.update!(status: :accepted)
      driver.update!(status: :on_delivery)
      delivery_request.record_event!(:driver_accepted, driver_id: driver.id)
    end

    def reject_request
      delivery_request.record_event!(:driver_rejected, driver_id: driver.id)
      delivery_request.update!(driver: nil, status: :finding_driver)
    end

    def accept?
      decision == :accept
    end

    def decision_past_tense
      accept? ? "accepted" : "rejected"
    end
  end
end
