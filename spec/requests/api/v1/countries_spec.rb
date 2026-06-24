require "rails_helper"

RSpec.describe "Api::V1::Countries", type: :request do
  describe "GET /api/v1/countries" do
    it "lists countries without requiring authentication" do
      create(:country, name: "Kenya", code: "KE")
      create(:country, name: "Uganda", code: "UG")

      get "/api/v1/countries"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |c| c["name"] }).to eq(%w[Kenya Uganda])
    end
  end
end
