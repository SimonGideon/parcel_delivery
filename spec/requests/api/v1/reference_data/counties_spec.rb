require "rails_helper"

RSpec.describe "Api::V1::Counties", type: :request do
  describe "GET /api/v1/counties" do
    it "lists counties without requiring authentication" do
      kenya = create(:country, name: "Kenya")
      create(:county, country: kenya, name: "Nairobi")
      create(:county, country: kenya, name: "Mombasa")

      get "/api/v1/counties"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |c| c["name"] }).to eq(%w[Mombasa Nairobi])
    end

    it "filters by country_id when given" do
      kenya = create(:country, name: "Kenya")
      uganda = create(:country, name: "Uganda")
      create(:county, country: kenya, name: "Nairobi")
      create(:county, country: uganda, name: "Kampala")

      get "/api/v1/counties", params: { country_id: kenya.id }

      body = JSON.parse(response.body)
      expect(body["data"].map { |c| c["name"] }).to eq(["Nairobi"])
    end
  end
end
