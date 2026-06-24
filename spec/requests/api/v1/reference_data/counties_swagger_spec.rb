require "swagger_helper"

RSpec.describe "api/v1/counties", type: :request do
  path "/api/v1/counties" do
    get "Lists counties (reference data for address forms), optionally filtered by country" do
      tags "Reference Data"
      produces "application/json"

      parameter name: :country_id, in: :query, type: :integer, required: false

      response "200", "counties returned" do
        let(:country_id) { create(:country, name: "Kenya").id }
        before { create(:county, country: Country.find(country_id), name: "Nairobi") }
        run_test!
      end
    end
  end
end
