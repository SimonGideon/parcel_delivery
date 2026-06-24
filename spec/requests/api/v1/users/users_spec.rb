require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/users" do
    let(:params) do
      { user: { name: "Alice", email: "alice@example.com", password: "password123", phone: "+15551234" } }
    end

    it "creates a user and returns the standard success envelope" do
      expect {
        post "/api/v1/users", params: params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("User created successfully")
      expect(body.dig("data", "email")).to eq("alice@example.com")
      expect(body["data"]).not_to have_key("password_digest")
      expect(body["meta"]).to be_nil
    end

    it "rejects duplicate emails with the standard error envelope" do
      create(:user, email: "alice@example.com")

      post "/api/v1/users", params: params

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["success"]).to be false
      expect(body["message"]).to eq("Validation failed")
      expect(body["errors"]).to include(
        "field" => "email", "message" => "has already been taken", "code" => "taken"
      )
    end
  end
end
