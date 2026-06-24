require "swagger_helper"

RSpec.describe "api/v1/countries", type: :request do
  path "/api/v1/countries" do
    get "Lists countries (reference data for address forms)" do
      tags "Reference Data"
      produces "application/json"

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
                 meta: { type: :object, nullable: true, example: nil }
               },
               required: %w[success message data meta]

        before { create(:country, :kenya) }
        run_test!
      end
    end
  end
end
