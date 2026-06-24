require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/users" do
    let(:params) do
      { user: { name: "Alice", email: "alice@example.com", password: "password123", phone: "+15551234" } }
    end

    it "creates a user and never exposes password_digest" do
      expect {
        post "/api/v1/users", params: params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("data", "email")).to eq("alice@example.com")
      expect(body["data"]).not_to have_key("password_digest")
    end

    it "rejects duplicate emails" do
      create(:user, email: "alice@example.com")

      post "/api/v1/users", params: params

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body.dig("error", "code")).to eq("unprocessable_entity")
    end
  end
end
