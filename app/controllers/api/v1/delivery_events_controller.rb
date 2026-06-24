module Api
  module V1
    class DeliveryEventsController < ApplicationController
      include DeliveryRequestAuthorizable

      before_action :authenticate_user_or_driver!
      before_action :set_delivery_request

      def index
        events = @delivery_request.delivery_events
        render json: { data: events.map { |event| DeliveryEventSerializer.new(event).as_json } }
      end

      private

      def set_delivery_request
        @delivery_request = DeliveryRequest.find(params[:delivery_request_id])
        authorize_delivery_request_access!(@delivery_request)
      end
    end
  end
end
