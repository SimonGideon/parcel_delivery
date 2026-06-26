module DeliveryRequests
  class ListQuery
    SORT_COLUMNS = {
      "created_at" => "created_at",
      "updated_at" => "updated_at",
      "status" => "status",
      "package_weight" => "package_weight"
    }.freeze
    SORT_DIRECTIONS = %w[asc desc].freeze
    DRIVER_FILTERABLE_STATUSES = %w[
      finding_driver assigned accepted picked_up in_transit delivered cancelled
    ].freeze
    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100

    attr_reader :validation_error

    def initialize(params:, principal:, ability:)
      @params = params
      @principal = principal
      @ability = ability
    end

    def call
      @validation_error = validate
      return DeliveryRequest.none.page(1).per(DEFAULT_PER_PAGE) if validation_error

      apply_pagination(
        apply_order(
          apply_search(
            apply_filters(visible_delivery_requests)
          )
        )
      )
    end

    def filterable_statuses
      return DeliveryRequest.statuses.keys if customer?

      DRIVER_FILTERABLE_STATUSES
    end

    private

    attr_reader :params, :principal, :ability

    def visible_delivery_requests
      return DeliveryRequest.accessible_by(ability, :read) if customer?

      DeliveryRequest
        .left_joins(:delivery_events)
        .where(driver_id: principal.id)
        .or(
          DeliveryRequest
            .left_joins(:delivery_events)
            .where(delivery_events: { event_type: DeliveryEvent.event_types[:driver_rejected] })
            .where("delivery_events.metadata ->> 'driver_id' = ?", principal.id)
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
          OR delivery_requests.pickup_address ->> 'city' ILIKE :query
          OR delivery_requests.pickup_address ->> 'nearest_town' ILIKE :query
          OR delivery_requests.pickup_address ->> 'line1' ILIKE :query
          OR delivery_requests.delivery_address ->> 'city' ILIKE :query
          OR delivery_requests.delivery_address ->> 'nearest_town' ILIKE :query
          OR delivery_requests.delivery_address ->> 'line1' ILIKE :query
        SQL
        query: query
      )
    end

    def apply_order(scope)
      scope.order(sort_column => sort_direction)
    end

    def apply_pagination(scope)
      scope.page(page).per(per_page)
    end

    def validate
      return invalid_status_message if invalid_status?
      return "Invalid sort_by: #{params[:sort_by]}" if invalid_sort_by?
      return "Invalid sort_direction: #{params[:sort_direction]}" if invalid_sort_direction?
      return "created_from must be a valid ISO8601 date/time" if params[:created_from].present? && created_from.nil?
      return "created_to must be a valid ISO8601 date/time" if params[:created_to].present? && created_to.nil?
      return "page must be greater than 0" if params[:page].present? && page < 1
      return "per_page must be between 1 and #{MAX_PER_PAGE}" if params[:per_page].present? && !per_page.between?(1, MAX_PER_PAGE)
    end

    def invalid_status?
      params[:status].present? && filterable_statuses.exclude?(params[:status])
    end

    def invalid_status_message
      "Invalid status filter: #{params[:status]}. Allowed statuses: #{filterable_statuses.join(', ')}"
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

    def customer?
      principal.is_a?(User) && !principal.is_a?(Driver)
    end
  end
end
