require "rails_helper"

RSpec.describe "Api::V1::DriverLocations", type: :request do
  describe "POST /api/v1/driver_locations" do
    let(:driver) { create(:driver, password: "password123") }
    let(:params) { { driver_location: { latitude: 1.2921, longitude: 36.8219 } } }

    it "requires authentication" do
      post "/api/v1/driver_locations", params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it "records a location for the authenticated driver" do
      expect {
        post "/api/v1/driver_locations", params: params, headers: basic_auth_headers(driver.email, "password123")
      }.to change(driver.driver_locations, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("data", "driver_id")).to eq(driver.id)
    end

    it "rejects invalid credentials" do
      post "/api/v1/driver_locations", params: params, headers: basic_auth_headers(driver.email, "wrong-password")

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
