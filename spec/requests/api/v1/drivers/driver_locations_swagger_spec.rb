require "swagger_helper"

RSpec.describe "api/v1/driver_locations", type: :request do
  path "/api/v1/driver_locations" do
    post "Reports the authenticated driver's current location" do
      tags "Driver Locations"
      consumes "application/json"
      produces "application/json"
      security [{ bearer_auth: [] }]

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
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Location recorded successfully" },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     driver_id: { type: :string, format: :uuid },
                     latitude: { type: :number, example: 1.2921 },
                     longitude: { type: :number, example: 36.8219 },
                     recorded_at: { type: :string, format: "date-time" }
                   }
                 },
                 meta: { type: :object, nullable: true, example: nil }
               },
               required: %w[success message data meta]

        let(:driver) { create(:driver, password: "password123") }
        let(:Authorization) { "Bearer #{AuthToken.issue(driver)}" }
        let(:driver_location) { { driver_location: { latitude: 1.2921, longitude: 36.8219 } } }
        run_test!
      end

      response "401", "missing or invalid credentials" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string, example: "Missing Authorization header — log in and use the returned bearer token in Swagger" },
                 errors: { type: :array, items: { type: :object }, example: [] }
               },
               required: %w[success message errors]

        let(:Authorization) { "" }
        let(:driver_location) { { driver_location: { latitude: 1.2921, longitude: 36.8219 } } }
        run_test!
      end
    end
  end
end
