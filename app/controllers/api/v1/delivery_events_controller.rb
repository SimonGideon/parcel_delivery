module Api
  module V1
    class DeliveryEventsController < ApplicationController
      before_action :authenticate_user_or_driver!
      before_action :set_delivery_request

      # ?event_type= filters to one lifecycle event type.
      def index
        authorize! :read, @delivery_request

        if params[:event_type].present? && !DeliveryEvent.event_types.key?(params[:event_type])
          return render_error(message: "Invalid event_type filter: #{params[:event_type]}", status: :bad_request)
        end

        events = @delivery_request.delivery_events
        events = events.where(event_type: params[:event_type]) if params[:event_type].present?
        events = events.page(params[:page]).per(params[:per_page] || 25)

        render_success(
          data: events.map { |event| DeliveryEventSerializer.new(event).as_json },
          message: "Delivery events retrieved successfully",
          meta: pagination_meta(events)
        )
      end

      private

      def set_delivery_request
        @delivery_request = DeliveryRequest.find(params[:delivery_request_id])
      end
    end
  end
end
