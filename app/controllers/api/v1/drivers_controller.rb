module Api
  module V1
    class DriversController < ApplicationController
      # Registration is the one endpoint a driver can hit before they have
      # credentials, so it intentionally skips authenticate_driver!.

      def create
        driver = Driver.new(driver_params)

        if driver.save
          render_success(
            data: DriverSerializer.new(driver).as_json,
            message: "Driver created successfully",
            status: :created
          )
        else
          render_validation_errors(driver)
        end
      end

      private

      def driver_params
        params.require(:driver).permit(:name, :email, :password, :phone)
      end
    end
  end
end
