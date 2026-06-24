class DeliveryRequestSerializer
  def initialize(delivery_request)
    @delivery_request = delivery_request
  end

  def as_json(*_args)
    {
      id: delivery_request.id,
      status: delivery_request.status,
      package_description: delivery_request.package_description,
      package_weight: delivery_request.package_weight.to_f,
      pickup_address: AddressSerializer.new(delivery_request.pickup_address).as_json,
      delivery_address: AddressSerializer.new(delivery_request.delivery_address).as_json,
      user: { id: delivery_request.user_id, name: delivery_request.user&.name },
      driver: driver_summary,
      created_at: delivery_request.created_at.iso8601,
      updated_at: delivery_request.updated_at.iso8601
    }
  end

  private

  attr_reader :delivery_request

  def driver_summary
    return nil unless delivery_request.driver_id

    { id: delivery_request.driver_id, name: delivery_request.driver&.name }
  end
end
