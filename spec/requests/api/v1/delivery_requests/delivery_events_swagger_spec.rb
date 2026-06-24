require "swagger_helper"

RSpec.describe "api/v1/delivery_requests/events", type: :request do
  let(:user) { create(:user, password: "password123") }

  path "/api/v1/delivery_requests/{delivery_request_id}/events" do
    get "Lists the lifecycle event history for a delivery request" do
      tags "Delivery Events"
      produces "application/json"
      security [{ bearer_auth: [] }]

      parameter name: :delivery_request_id, in: :path, type: :string, format: :uuid

      response "200", "event history returned" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Delivery events retrieved successfully" },
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, format: :uuid },
                       event_type: {
                         type: :string,
                         enum: %w[created finding_driver driver_assigned driver_accepted driver_rejected
                                  picked_up in_transit delivered cancelled],
                         example: "created"
                       },
                       metadata: { type: :object },
                       occurred_at: { type: :string, format: "date-time" }
                     }
                   }
                 },
                 meta: { type: :object, nullable: true, example: nil }
               },
               required: %w[success message data meta]

        let(:Authorization) { "Bearer #{AuthToken.issue(user)}" }
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
