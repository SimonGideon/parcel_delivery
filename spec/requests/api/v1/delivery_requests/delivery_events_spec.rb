require "rails_helper"

RSpec.describe "Api::V1::DeliveryEvents", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:delivery_request) { create(:delivery_request, user: user) }

  describe "GET /api/v1/delivery_requests/:delivery_request_id/events" do
    it "returns the lifecycle event history in chronological order" do
      delivery_request.record_event!(:created)
      delivery_request.record_event!(:finding_driver)

      get "/api/v1/delivery_requests/#{delivery_request.id}/events",
        headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("Delivery events retrieved successfully")
      expect(body["data"].map { |e| e["event_type"] }).to eq(%w[created finding_driver])
      expect(body["meta"]).to include("current_page", "total_pages", "total_count")
    end

    it "filters by event_type via ?event_type=" do
      delivery_request.record_event!(:created)
      delivery_request.record_event!(:finding_driver)

      get "/api/v1/delivery_requests/#{delivery_request.id}/events",
        params: { event_type: "created" },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |e| e["event_type"] }).to eq(["created"])
    end

    it "returns 400 for an unknown event_type filter" do
      get "/api/v1/delivery_requests/#{delivery_request.id}/events",
        params: { event_type: "bogus" },
        headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 404 for a user who does not own the delivery request" do
      other_user = create(:user, password: "password123")

      get "/api/v1/delivery_requests/#{delivery_request.id}/events",
        headers: basic_auth_headers(other_user.email, "password123")

      expect(response).to have_http_status(:not_found)
    end
  end
end
