require "swagger_helper"

RSpec.describe "api/v1/driver_locations", type: :request do
  path "/api/v1/driver_locations" do
    post "Reports the authenticated driver's current location" do
      tags "Driver Locations"
      consumes "application/json"
      produces "application/json"
      security [{ basic_auth: [] }]

      parameter name: :driver_location, in: :body, schema: {
        type: :object,
        properties: {
          driver_location: {
            type: :object,
            properties: {
              latitude: { type: :number, example: 1.2921 },
              longitude: { type: :number, example: 36.8219 }
            },
            required: %w[latitude longitude]
          }
        }
      }

      response "201", "location recorded" do
        let(:driver) { create(:driver, password: "password123") }
        let(:Authorization) { ActionController::HttpAuthentication::Basic.encode_credentials(driver.email, "password123") }
        let(:driver_location) { { driver_location: { latitude: 1.2921, longitude: 36.8219 } } }
        run_test!
      end

      response "401", "missing or invalid credentials" do
        let(:Authorization) { "" }
        let(:driver_location) { { driver_location: { latitude: 1.2921, longitude: 36.8219 } } }
        run_test!
      end
    end
  end
end
