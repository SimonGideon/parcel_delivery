require "swagger_helper"

RSpec.describe "api/v1/counties", type: :request do
  path "/api/v1/counties" do
    get "Lists counties (reference data for address forms), optionally filtered by country" do
      tags "Reference Data"
      produces "application/json"

      parameter name: :country_id, in: :query, type: :string, format: :uuid, required: false
      parameter name: :q, in: :query, type: :string, required: false,
        description: "Search counties by name (case-insensitive, partial match)"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "counties returned" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Counties retrieved successfully" },
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, format: :uuid },
                       name: { type: :string, example: "Nairobi" },
                       country_id: { type: :string, format: :uuid }
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

        let(:country_id) { create(:country, name: "Kenya").id }
        before { create(:county, country: Country.find(country_id), name: "Nairobi") }
        run_test!
      end
    end
  end
end
