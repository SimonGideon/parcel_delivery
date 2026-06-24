require "rails_helper"

RSpec.describe "Api::V1::Drivers", type: :request do
  describe "POST /api/v1/drivers" do
    let(:params) do
      { driver: { name: "Bob", email: "bob@example.com", password: "password123", phone: "+15557654" } }
    end

    it "creates a driver, defaulting to available status" do
      expect {
        post "/api/v1/drivers", params: params
      }.to change(Driver, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("Driver created successfully")
      expect(body.dig("data", "status")).to eq("available")
      expect(body["meta"]).to be_nil
    end

    it "rejects duplicate emails with the standard error envelope" do
      create(:driver, email: "bob@example.com")

      post "/api/v1/drivers", params: params

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["success"]).to be false
      expect(body["message"]).to eq("Validation failed")
      expect(body["errors"]).to include("field" => "email", "message" => "has already been taken", "code" => "taken")
    end
  end
end
