require "rails_helper"

RSpec.describe "Api::V1::Countries", type: :request do
  describe "GET /api/v1/countries" do
    it "lists countries without requiring authentication" do
      create(:country, name: "Kenya", iso2: "KE")
      create(:country, name: "Uganda", iso2: "UG")

      get "/api/v1/countries"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |c| c["name"] }).to eq(%w[Kenya Uganda])
    end

    it "includes the enriched reference fields" do
      create(:country, :kenya)

      get "/api/v1/countries"

      kenya = JSON.parse(response.body)["data"].first
      expect(kenya).to include(
        "iso2" => "KE", "iso3" => "KEN", "phonecode" => "+254", "capital" => "Nairobi",
        "currency" => "KES", "currency_symbol" => "KSh", "region" => "Africa"
      )
      expect(kenya["latitude"]).to eq(1.0)
      expect(kenya["longitude"]).to eq(38.0)
    end
  end
end
