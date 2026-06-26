module Api
  module V1
    class DeliveryRequestsController < ApplicationController
      before_action :authenticate_user!, only: %i[create customer_index cancel]
      before_action :authenticate_user_or_driver!, only: %i[show]
      before_action :authenticate_driver!, only: %i[driver_index accept reject pick_up deliver]
      before_action :set_delivery_request, only: %i[show cancel accept reject pick_up deliver]

      def customer_index
        render_delivery_requests
      end

      def driver_index
        render_delivery_requests
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

        result = DeliveryRequests::DriverDecision.new(
          delivery_request: @delivery_request,
          driver: current_driver,
          decision: :accept
        ).call
        render_success(data: DeliveryRequestSerializer.new(result).as_json, message: "Delivery request accepted")
      end

      def cancel
        authorize! :cancel, @delivery_request

        result = DeliveryRequests::Cancel.new(delivery_request: @delivery_request, user: current_user).call
        render_success(data: DeliveryRequestSerializer.new(result).as_json, message: "Delivery request cancelled")
      end

      def reject
        authorize! :reject, @delivery_request

        result = DeliveryRequests::DriverDecision.new(
          delivery_request: @delivery_request,
          driver: current_driver,
          decision: :reject
        ).call
        render_success(data: DeliveryRequestSerializer.new(result).as_json, message: "Delivery request rejected")
      end

      def pick_up
        authorize! :pick_up, @delivery_request

        result = DeliveryRequests::PickUp.new(delivery_request: @delivery_request, driver: current_driver).call
        render_success(data: DeliveryRequestSerializer.new(result).as_json, message: "Delivery request picked up")
      end

      def deliver
        authorize! :deliver, @delivery_request

        result = DeliveryRequests::Deliver.new(delivery_request: @delivery_request, driver: current_driver).call
        render_success(data: DeliveryRequestSerializer.new(result).as_json, message: "Delivery request delivered")
      end

      private

      def render_delivery_requests
        query = DeliveryRequests::ListQuery.new(
          params: params,
          principal: current_user || current_driver,
          ability: current_ability
        )
        delivery_requests = query.call.includes(:user, :driver)
        return render_error(message: query.validation_error, status: :bad_request) if query.validation_error

        render_success(
          data: delivery_requests.map { |dr| DeliveryRequestSerializer.new(dr).as_json },
          message: "Delivery requests retrieved successfully",
          meta: pagination_meta(delivery_requests).merge(
            filters: { allowed_statuses: query.filterable_statuses }
          )
        )
      end

      def set_delivery_request
        @delivery_request = DeliveryRequest
          .includes(:user, :driver)
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
