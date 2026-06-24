require "swagger_helper"

RSpec.describe "api/v1/delivery_requests/events", type: :request do
  let(:user) { create(:user, password: "password123") }

  path "/api/v1/delivery_requests/{delivery_request_id}/events" do
    get "Lists the lifecycle event history for a delivery request" do
      tags "Delivery Events"
      produces "application/json"
      security [{ basic_auth: [] }]

      parameter name: :delivery_request_id, in: :path, type: :string, format: :uuid

      response "200", "event history returned" do
        let(:Authorization) { ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password123") }
        let(:delivery_request_id) do
          delivery_request = create(:delivery_request, user: user)
          delivery_request.record_event!(:created)
          delivery_request.id
        end
        run_test!
      end
    end
  end
end
