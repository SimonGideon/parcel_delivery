require "swagger_helper"

RSpec.describe "api/v1/drivers", type: :request do
  path "/api/v1/drivers" do
    post "Registers a driver account" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"

      parameter name: :driver, in: :body, schema: {
        type: :object,
        properties: {
          driver: {
            type: :object,
            properties: {
              name: { type: :string, example: "Bob" },
              email: { type: :string, example: "bob@example.com" },
              password: { type: :string, format: :password, example: "password123" },
              phone: { type: :string, example: "+15557654" }
            },
            required: %w[name email password]
          }
        }
      }

      response "201", "driver created" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Driver created successfully" },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     name: { type: :string, example: "Bob" },
                     email: { type: :string, example: "bob@example.com" },
                     phone: { type: :string, nullable: true, example: "+15557654" },
                     status: { type: :string, enum: %w[available unavailable on_delivery], example: "available" },
                     created_at: { type: :string, format: "date-time" }
                   }
                 },
                 meta: { type: :object, nullable: true, example: nil }
               },
               required: %w[success message data meta]

        let(:driver) { { driver: { name: "Bob", email: "bob@example.com", password: "password123" } } }
        run_test!
      end

      response "422", "validation failed" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string, example: "Validation failed" },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       field: { type: :string, example: "email" },
                       message: { type: :string, example: "has already been taken" },
                       code: { type: :string, example: "taken" }
                     }
                   }
                 }
               },
               required: %w[success message errors]

        let(:driver) { { driver: { name: "Bob", email: "bob@example.com", password: "password123" } } }
        before { create(:driver, email: "bob@example.com") }
        run_test!
      end
    end
  end
end
