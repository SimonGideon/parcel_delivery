require "swagger_helper"

RSpec.describe "api/v1/countries", type: :request do
  path "/api/v1/countries" do
    get "Lists countries (reference data for address forms)" do
      tags "Reference Data"
      produces "application/json"

      parameter name: :q, in: :query, type: :string, required: false,
        description: "Search countries by name (case-insensitive, partial match)"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "countries returned" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Countries retrieved successfully" },
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, format: :uuid },
                       name: { type: :string, example: "Kenya" },
                       iso2: { type: :string, example: "KE" },
                       iso3: { type: :string, nullable: true, example: "KEN" },
                       phonecode: { type: :string, nullable: true, example: "+254" },
                       capital: { type: :string, nullable: true, example: "Nairobi" },
                       currency: { type: :string, nullable: true, example: "KES" },
                       currency_symbol: { type: :string, nullable: true, example: "KSh" },
                       region: { type: :string, nullable: true, example: "Africa" },
                       latitude: { type: :number, nullable: true, example: 1.0 },
                       longitude: { type: :number, nullable: true, example: 38.0 },
                       timezone: { type: :string, nullable: true, example: "Africa/Nairobi" },
                       gmt_offset: { type: :integer, nullable: true, example: 180 }
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

        before { create(:country, :kenya) }
        run_test!
      end
    end
  end
end
