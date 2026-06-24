require "swagger_helper"

RSpec.describe "api/v1/delivery_requests", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:driver) { create(:driver, password: "password123", status: :available) }
  let(:user_auth) { ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password123") }
  let(:driver_auth) { ActionController::HttpAuthentication::Basic.encode_credentials(driver.email, "password123") }

  path "/api/v1/delivery_requests" do
    get "Lists the authenticated customer's or driver's delivery requests" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ basic_auth: [] }]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "requests returned" do
        let(:Authorization) { user_auth }
        before { create(:delivery_request, user: user) }
        run_test!
      end
    end

    post "Creates a delivery request and triggers nearest-driver search" do
      tags "Delivery Requests"
      consumes "application/json"
      produces "application/json"
      security [{ basic_auth: [] }]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :delivery_request, in: :body, schema: {
        type: :object,
        properties: {
          delivery_request: {
            type: :object,
            properties: {
              package_description: { type: :string, example: "Books" },
              package_weight: { type: :number, example: 2.5 },
              pickup_address: {
                type: :object,
                properties: {
                  line1: { type: :string, example: "123 Main St" },
                  city: { type: :string, example: "Nairobi" },
                  latitude: { type: :number, example: 1.2945 },
                  longitude: { type: :number, example: 36.8228 }
                },
                required: %w[line1 city latitude longitude]
              },
              delivery_address: {
                type: :object,
                properties: {
                  line1: { type: :string, example: "456 Side St" },
                  city: { type: :string, example: "Nairobi" },
                  latitude: { type: :number, example: 1.3 },
                  longitude: { type: :number, example: 36.83 }
                },
                required: %w[line1 city latitude longitude]
              }
            },
            required: %w[package_description package_weight pickup_address delivery_address]
          }
        }
      }

      response "201", "delivery request created" do
        let(:Authorization) { user_auth }
        let(:delivery_request) do
          {
            delivery_request: {
              package_description: "Books",
              package_weight: 2.5,
              pickup_address: { line1: "123 Main St", city: "Nairobi", latitude: 1.2945, longitude: 36.8228 },
              delivery_address: { line1: "456 Side St", city: "Nairobi", latitude: 1.3, longitude: 36.83 }
            }
          }
        end
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}" do
    get "Retrieves a delivery request visible to its owner or assigned driver" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ basic_auth: [] }]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response "200", "delivery request found" do
        let(:Authorization) { user_auth }
        let(:id) { create(:delivery_request, user: user).id }
        run_test!
      end

      response "404", "not visible to this principal" do
        let(:Authorization) { user_auth }
        let(:id) { create(:delivery_request).id }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}/accept" do
    post "Driver accepts an assigned delivery request" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ basic_auth: [] }]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response "200", "request accepted" do
        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :assigned).id }
        run_test!
      end

      response "409", "request is not in assigned status" do
        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :accepted).id }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}/reject" do
    post "Driver rejects an assigned delivery request, triggering re-assignment" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ basic_auth: [] }]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response "200", "request rejected" do
        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :assigned).id }
        run_test!
      end
    end
  end
end
