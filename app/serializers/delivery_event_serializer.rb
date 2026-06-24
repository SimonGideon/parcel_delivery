class DeliveryEventSerializer
  def initialize(event)
    @event = event
  end

  def as_json(*_args)
    {
      id: event.id,
      event_type: event.event_type,
      metadata: event.metadata,
      occurred_at: event.occurred_at.iso8601
    }
  end

  private

  attr_reader :event
end
