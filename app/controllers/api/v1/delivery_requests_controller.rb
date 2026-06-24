module Api
  module V1
    class DeliveryRequestsController < ApplicationController
      before_action :authenticate_user!, only: %i[create]
      before_action :authenticate_user_or_driver!, only: %i[index show]
      before_action :authenticate_driver!, only: %i[accept reject]
      before_action :set_delivery_request, only: %i[show accept reject]

      # Customers see their own requests; drivers see requests assigned to them.
      def index
        delivery_requests = DeliveryRequest
          .accessible_by(current_ability, :read)
          .includes(:user, :driver, pickup_address: %i[country county], delivery_address: %i[country county])
          .order(created_at: :desc)
          .page(params[:page])
          .per(params[:per_page] || 25)

        render_success(
          data: delivery_requests.map { |dr| DeliveryRequestSerializer.new(dr).as_json },
          message: "Delivery requests retrieved successfully",
          meta: pagination_meta(delivery_requests)
        )
      end

      def show
        authorize! :read, @delivery_request

        render_success(
          data: DeliveryRequestSerializer.new(@delivery_request).as_json,
          message: "Delivery request retrieved successfully"
        )
      end

      def create
        authorize! :create, DeliveryRequest

        delivery_request = DeliveryRequests::Creator.new(
          user: current_user,
          pickup_address_attrs: pickup_address_params.to_h,
          delivery_address_attrs: delivery_address_params.to_h,
          package_description: delivery_request_params[:package_description],
          package_weight: delivery_request_params[:package_weight]
        ).call

        render_success(
          data: DeliveryRequestSerializer.new(delivery_request).as_json,
          message: "Delivery request created successfully",
          status: :created
        )
      end

      def accept
        authorize! :accept, @delivery_request

        result = DeliveryRequests::Accept.new(delivery_request: @delivery_request, driver: current_driver).call
        render_success(data: DeliveryRequestSerializer.new(result).as_json, message: "Delivery request accepted")
      end

      def reject
        authorize! :reject, @delivery_request

        result = DeliveryRequests::Reject.new(delivery_request: @delivery_request, driver: current_driver).call
        render_success(data: DeliveryRequestSerializer.new(result).as_json, message: "Delivery request rejected")
      end

      private

      def set_delivery_request
        @delivery_request = DeliveryRequest
          .includes(:user, :driver, pickup_address: %i[country county], delivery_address: %i[country county])
          .find(params[:id])
      end

      def delivery_request_params
        params.require(:delivery_request).permit(:package_description, :package_weight)
      end

      ADDRESS_PARAMS = %i[
        line1 line2 city county_id nearest_town building_name floor door
        instructions postal_code country_id latitude longitude
      ].freeze

      def pickup_address_params
        params.require(:delivery_request).require(:pickup_address).permit(ADDRESS_PARAMS)
      end

      def delivery_address_params
        params.require(:delivery_request).require(:delivery_address).permit(ADDRESS_PARAMS)
      end
    end
  end
end
