require "swagger_helper"

RSpec.describe "api/v1/countries", type: :request do
  path "/api/v1/countries" do
    get "Lists countries (reference data for address forms)" do
      tags "Reference Data"
      produces "application/json"

      response "200", "countries returned" do
        before { create(:country, name: "Kenya", iso2: "KE") }
        run_test!
      end
    end
  end
end
