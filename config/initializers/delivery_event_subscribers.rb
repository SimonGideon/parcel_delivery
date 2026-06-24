# Event-driven dispatch for the delivery lifecycle: DeliveryRequest#record_event!
# fires an ActiveSupport::Notifications event for every DeliveryEvent it writes.
# Subscribers here react to those events asynchronously, instead of services
# calling each other directly -- creating a request doesn't need to know that
# driver assignment happens next, and a rejection doesn't need to know that it
# triggers a re-search.
%w[delivery_request.created delivery_request.driver_rejected].each do |event_name|
  ActiveSupport::Notifications.subscribe(event_name) do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    AssignNearestDriverJob.perform_later(event.payload[:delivery_request_id])
  end
end
