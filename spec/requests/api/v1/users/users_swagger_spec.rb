require "swagger_helper"

RSpec.describe "api/v1/users", type: :request do
  path "/api/v1/users" do
    post "Registers a customer account" do
      tags "Users"
      consumes "application/json"
      produces "application/json"

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              name: { type: :string, example: "Alice" },
              email: { type: :string, example: "alice@example.com" },
              password: { type: :string, format: :password, example: "password123" },
              phone: { type: :string, example: "+15551234" }
            },
            required: %w[name email password]
          }
        }
      }

      response "201", "user created" do
        let(:user) { { user: { name: "Alice", email: "alice@example.com", password: "password123" } } }
        run_test!
      end

      response "422", "validation failed" do
        let(:user) { { user: { name: "Alice", email: "not-an-email", password: "password123" } } }
        run_test!
      end
    end
  end
end
