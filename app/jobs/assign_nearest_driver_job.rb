class AssignNearestDriverJob < ApplicationJob
  queue_as :default
  retry_on ActiveRecord::Deadlocked, attempts: 3

  def perform(delivery_request_id)
    delivery_request = DeliveryRequest.find_by(id: delivery_request_id)
    return if delivery_request.nil?

    DeliveryRequests::AssignDriver.new(delivery_request).call
  end
end
