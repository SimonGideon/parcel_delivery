module DeliveryRequests
  class Creator
    def initialize(user:, pickup_address_attrs:, delivery_address_attrs:, package_description:, package_weight:)
      @user = user
      @pickup_address_attrs = pickup_address_attrs
      @delivery_address_attrs = delivery_address_attrs
      @package_description = package_description
      @package_weight = package_weight
    end

    def call
      ActiveRecord::Base.transaction do
        delivery_request = user.delivery_requests.create!(
          pickup_address: pickup_address_attrs,
          delivery_address: delivery_address_attrs,
          package_description: package_description,
          package_weight: package_weight,
          status: :pending
        )

        delivery_request.record_event!(:created)
        delivery_request
      end
    end

    private

    attr_reader :user, :pickup_address_attrs, :delivery_address_attrs, :package_description, :package_weight
  end
end
