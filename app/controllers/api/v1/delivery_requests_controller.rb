module Api
  module V1
    class DeliveryRequestsController < ApplicationController
      include DeliveryRequestAuthorizable

      before_action :authenticate_user!, only: %i[create]
      before_action :authenticate_user_or_driver!, only: %i[index show]
      before_action :authenticate_driver!, only: %i[accept reject]
      before_action :set_delivery_request, only: %i[show]
      before_action :set_own_delivery_request_for_driver, only: %i[accept reject]

      # Customers see their own requests; drivers see requests assigned to them.
      def index
        scope = current_user ? current_user.delivery_requests : current_driver.delivery_requests
        delivery_requests = scope
          .includes(:user, :driver, :pickup_address, :delivery_address)
          .order(created_at: :desc)
          .page(params[:page])
          .per(params[:per_page] || 25)

        render json: {
          data: delivery_requests.map { |dr| DeliveryRequestSerializer.new(dr).as_json },
          meta: pagination_meta(delivery_requests)
        }
      end

      def show
        authorize_delivery_request_access!(@delivery_request)
        return if performed?

        render json: { data: DeliveryRequestSerializer.new(@delivery_request).as_json }
      end

      def create
        delivery_request = DeliveryRequests::Creator.new(
          user: current_user,
          pickup_address_attrs: pickup_address_params.to_h,
          delivery_address_attrs: delivery_address_params.to_h,
          package_description: delivery_request_params[:package_description],
          package_weight: delivery_request_params[:package_weight]
        ).call

        render json: { data: DeliveryRequestSerializer.new(delivery_request).as_json }, status: :created
      end

      def accept
        result = DeliveryRequests::Accept.new(delivery_request: @delivery_request, driver: current_driver).call
        render json: { data: DeliveryRequestSerializer.new(result).as_json }
      end

      def reject
        result = DeliveryRequests::Reject.new(delivery_request: @delivery_request, driver: current_driver).call
        render json: { data: DeliveryRequestSerializer.new(result).as_json }
      end

      private

      def set_delivery_request
        @delivery_request = DeliveryRequest
          .includes(:user, :driver, :pickup_address, :delivery_address)
          .find(params[:id])
      end

      # Scoping to the driver's own assigned requests means a driver probing
      # someone else's request id gets the same 404 as a nonexistent id,
      # rather than a 409 that would confirm it exists.
      def set_own_delivery_request_for_driver
        @delivery_request = current_driver.delivery_requests
          .includes(:user, :driver, :pickup_address, :delivery_address)
          .find(params[:id])
      end

      def delivery_request_params
        params.require(:delivery_request).permit(:package_description, :package_weight)
      end

      def pickup_address_params
        params.require(:delivery_request).require(:pickup_address)
          .permit(:line1, :line2, :city, :county, :nearest_town, :postal_code, :country, :latitude, :longitude)
      end

      def delivery_address_params
        params.require(:delivery_request).require(:delivery_address)
          .permit(:line1, :line2, :city, :county, :nearest_town, :postal_code, :country, :latitude, :longitude)
      end
    end
  end
end
