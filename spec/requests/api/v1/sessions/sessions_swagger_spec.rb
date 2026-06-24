require "swagger_helper"

RSpec.describe "api/v1/login", type: :request do
  path "/api/v1/login" do
    post "Logs in with username/password and returns a bearer token" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      description <<~DESC.squish
        Enter your account email as username and your password. Copy the returned
        token into Swagger's Authorize dialog. Use principal_type when the same
        email exists for both a customer and a driver.
      DESC

      parameter name: :login, in: :body, schema: {
        type: :object,
        properties: {
          login: {
            type: :object,
            properties: {
              username: { type: :string, example: "alice@example.com" },
              password: { type: :string, format: :password, example: "password123" },
              principal_type: { type: :string, enum: %w[user driver], nullable: true, example: "user" }
            },
            required: %w[username password]
          }
        },
        required: %w[login]
      }

      response "200", "credentials are valid" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Login successful" },
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string, enum: %w[user driver], example: "user" },
                     token: { type: :string },
                     token_type: { type: :string, example: "Bearer" },
                     expires_in: { type: :integer, example: 86_400 },
                     principal: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         name: { type: :string, example: "Simon" },
                         email: { type: :string, example: "simon@example.com" },
                         phone: { type: :string, nullable: true },
                         created_at: { type: :string, format: "date-time" }
                       }
                     }
                   }
                 },
                 meta: { type: :object, nullable: true, example: nil }
               },
               required: %w[success message data meta]

        let(:user) { create(:user, password: "password123") }
        let(:login) { { login: { username: user.email, password: "password123" } } }
        run_test!
      end

      response "401", "missing or invalid credentials" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string, example: "Invalid username or password" },
                 errors: { type: :array, items: { type: :object }, example: [] }
               },
               required: %w[success message errors]

        let(:login) { { login: { username: "nobody@example.com", password: "wrong-password" } } }
        run_test!
      end
    end
  end
end
