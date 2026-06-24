require "swagger_helper"

RSpec.describe "api/v1/users", type: :request do
  path "/api/v1/users" do
    post "Registers a customer account" do
      tags "Authentication"
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
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "User created successfully" },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     name: { type: :string, example: "Alice" },
                     email: { type: :string, example: "alice@example.com" },
                     phone: { type: :string, nullable: true, example: "+15551234" },
                     created_at: { type: :string, format: "date-time" }
                   }
                 },
                 meta: { type: :object, nullable: true, example: nil }
               },
               required: %w[success message data meta]

        let(:user) { { user: { name: "Alice", email: "alice@example.com", password: "password123" } } }
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

        let(:user) { { user: { name: "Alice", email: "alice@example.com", password: "password123" } } }
        before { create(:user, email: "alice@example.com") }
        run_test!
      end
    end
  end
end
