require "swagger_helper"

RSpec.describe "api/v1/delivery_requests/events", type: :request do
  let(:user) { create(:user, password: "password123") }

  path "/api/v1/delivery_requests/{delivery_request_id}/events" do
    get "Lists the lifecycle event history for a delivery request" do
      tags "Delivery Events"
      produces "application/json"
      security [{ bearer_auth: [] }]

      parameter name: :delivery_request_id, in: :path, type: :string, format: :uuid
      parameter name: :event_type, in: :query, type: :string, required: false,
        enum: %w[created finding_driver driver_assigned driver_accepted driver_rejected
                 picked_up in_transit delivered cancelled],
        description: "Filter to one lifecycle event type"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

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
                 meta: {
                   type: :object,
                   properties: {
                     current_page: { type: :integer, example: 1 },
                     next_page: { type: :integer, nullable: true },
                     prev_page: { type: :integer, nullable: true },
                     total_pages: { type: :integer, example: 1 },
                     total_count: { type: :integer, example: 1 }
                   }
                 }
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

      response "400", "unknown event_type filter" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string, example: "Invalid event_type filter: bogus" },
                 errors: { type: :array, items: { type: :object }, example: [] }
               },
               required: %w[success message errors]

        let(:Authorization) { "Bearer #{AuthToken.issue(user)}" }
        let(:event_type) { "bogus" }
        let(:delivery_request_id) { create(:delivery_request, user: user).id }
        run_test!
      end
    end
  end
end
