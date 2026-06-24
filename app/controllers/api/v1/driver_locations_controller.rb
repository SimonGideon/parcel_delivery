module Api
  module V1
    class DriverLocationsController < ApplicationController
      before_action :authenticate_driver!

      # A driver reports their own current position; there is no concept of
      # reporting another driver's location, so it's always current_driver.
      def create
        authorize! :create, DriverLocation

        location = current_driver.driver_locations.create!(driver_location_params)

        render_success(
          data: DriverLocationSerializer.new(location).as_json,
          message: "Location recorded successfully",
          status: :created
        )
      end

      private

      def driver_location_params
        params.require(:driver_location).permit(:latitude, :longitude)
      end
    end
  end
end
