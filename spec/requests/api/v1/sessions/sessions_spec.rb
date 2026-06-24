require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/login" do
    it "returns a bearer token for valid customer credentials" do
      user = create(:user, password: "password123")

      post "/api/v1/login", params: { login: { username: user.email, password: "password123" } }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("Login successful")
      expect(body.dig("data", "type")).to eq("user")
      expect(body.dig("data", "token_type")).to eq("Bearer")
      expect(body.dig("data", "token")).to be_present
      expect(body.dig("data", "principal", "id")).to eq(user.id)
      expect(body["data"]["principal"]).not_to have_key("password_digest")
    end

    it "returns a bearer token for valid driver credentials" do
      driver = create(:driver, password: "password123")

      post "/api/v1/login", params: { login: { username: driver.email, password: "password123" } }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("data", "type")).to eq("driver")
      expect(body.dig("data", "principal", "id")).to eq(driver.id)
      expect(body.dig("data", "token")).to be_present
    end

    it "returns a token that authorizes protected requests" do
      user = create(:user, password: "password123")

      post "/api/v1/login", params: { login: { username: user.email, password: "password123" } }
      token = JSON.parse(response.body).dig("data", "token")

      get "/api/v1/delivery_requests", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
    end

    it "rejects an unknown email" do
      post "/api/v1/login", params: { login: { username: "nobody@example.com", password: "whatever" } }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["success"]).to be false
      expect(body["message"]).to eq("Invalid username or password")
    end

    it "rejects a known email with the wrong password" do
      user = create(:user, password: "password123")

      post "/api/v1/login", params: { login: { username: user.email, password: "wrong-password" } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a request with no credentials" do
      post "/api/v1/login"

      expect(response).to have_http_status(:bad_request)
    end
  end
end
