module Api
  module V1
    class DeliveryRequestsController < ApplicationController
      before_action :authenticate_user!, only: %i[create]
      before_action :authenticate_user_or_driver!, only: %i[index show]
      before_action :authenticate_driver!, only: %i[accept reject]
      before_action :set_delivery_request, only: %i[show accept reject]

      SORT_COLUMNS = {
        "created_at" => "created_at",
        "updated_at" => "updated_at",
        "status" => "status",
        "package_weight" => "package_weight"
      }.freeze
      SORT_DIRECTIONS = %w[asc desc].freeze
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      # Customers see their own requests. Drivers see their assigned/current
      # requests plus historical requests they already acted on.
      def index
        return render_error(message: validation_error, status: :bad_request) if validation_error

        delivery_requests = visible_delivery_requests
          .includes(:user, :driver, pickup_address: %i[country county], delivery_address: %i[country county])
        delivery_requests = apply_filters(delivery_requests)
        delivery_requests = apply_search(delivery_requests)
        delivery_requests = delivery_requests
          .order(sort_column => sort_direction)
          .page(params[:page])
          .per(per_page)

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

      def visible_delivery_requests
        return DeliveryRequest.accessible_by(current_ability, :read) if current_user

        DeliveryRequest
          .left_joins(:delivery_events)
          .where(driver_id: current_driver.id)
          .or(
            DeliveryRequest
              .left_joins(:delivery_events)
              .where(delivery_events: { event_type: DeliveryEvent.event_types[:driver_rejected] })
              .where("delivery_events.metadata ->> 'driver_id' = ?", current_driver.id)
          )
          .distinct
      end

      def apply_filters(scope)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where("delivery_requests.created_at >= ?", created_from) if created_from
        scope = scope.where("delivery_requests.created_at <= ?", created_to) if created_to
        scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
        scope
      end

      def apply_search(scope)
        return scope if params[:q].blank?

        query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
        scope.where(
          <<~SQL.squish,
            delivery_requests.package_description ILIKE :query
            OR EXISTS (
              SELECT 1 FROM addresses pickup_addresses
              WHERE pickup_addresses.id = delivery_requests.pickup_address_id
                AND (
                  pickup_addresses.city ILIKE :query
                  OR pickup_addresses.nearest_town ILIKE :query
                  OR pickup_addresses.line1 ILIKE :query
                )
            )
            OR EXISTS (
              SELECT 1 FROM addresses delivery_addresses
              WHERE delivery_addresses.id = delivery_requests.delivery_address_id
                AND (
                  delivery_addresses.city ILIKE :query
                  OR delivery_addresses.nearest_town ILIKE :query
                  OR delivery_addresses.line1 ILIKE :query
                )
            )
          SQL
          query: query
        )
      end

      def validation_error
        return "Invalid status filter: #{params[:status]}" if invalid_status?
        return "Invalid sort_by: #{params[:sort_by]}" if invalid_sort_by?
        return "Invalid sort_direction: #{params[:sort_direction]}" if invalid_sort_direction?
        return "created_from must be a valid ISO8601 date/time" if params[:created_from].present? && created_from.nil?
        return "created_to must be a valid ISO8601 date/time" if params[:created_to].present? && created_to.nil?
        return "page must be greater than 0" if params[:page].present? && page < 1
        return "per_page must be between 1 and #{MAX_PER_PAGE}" if params[:per_page].present? && !per_page.between?(1, MAX_PER_PAGE)
      end

      def invalid_status?
        params[:status].present? && !DeliveryRequest.statuses.key?(params[:status])
      end

      def invalid_sort_by?
        params[:sort_by].present? && !SORT_COLUMNS.key?(params[:sort_by])
      end

      def invalid_sort_direction?
        params[:sort_direction].present? && SORT_DIRECTIONS.exclude?(params[:sort_direction].to_s.downcase)
      end

      def sort_column
        SORT_COLUMNS.fetch(params[:sort_by].presence || "created_at")
      end

      def sort_direction
        (params[:sort_direction].presence || "desc").to_s.downcase
      end

      def page
        params[:page].to_i
      end

      def per_page
        (params[:per_page].presence || DEFAULT_PER_PAGE).to_i
      end

      def created_from
        @created_from ||= parse_time(params[:created_from])
      end

      def created_to
        @created_to ||= parse_time(params[:created_to])
      end

      def parse_time(value)
        return if value.blank?

        Time.zone.iso8601(value)
      rescue ArgumentError
        nil
      end

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
