require "swagger_helper"

RSpec.describe "api/v1/drivers", type: :request do
  path "/api/v1/drivers" do
    post "Registers a driver account" do
      tags "Drivers"
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
        let(:driver) { { driver: { name: "Bob", email: "bob@example.com", password: "password123" } } }
        run_test!
      end
    end
  end
end
