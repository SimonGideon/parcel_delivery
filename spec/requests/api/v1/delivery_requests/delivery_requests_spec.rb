require "rails_helper"

RSpec.describe "Api::V1::DeliveryRequests", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:driver) { create(:driver, password: "password123", status: :available) }

  describe "POST /api/v1/delivery_requests" do
    let(:params) do
      {
        delivery_request: {
          package_description: "Books",
          package_weight: 2.5,
          pickup_address: { line1: "123 Main St", city: "Nairobi", latitude: 1.2945, longitude: 36.8228 },
          delivery_address: { line1: "456 Side St", city: "Nairobi", latitude: 1.3, longitude: 36.83 }
        }
      }
    end

    it "requires user authentication" do
      post "/api/v1/delivery_requests", params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it "persists the request as pending and enqueues nearest-driver search" do
      expect {
        post "/api/v1/delivery_requests", params: params, headers: basic_auth_headers(user.email, "password123")
      }.to have_enqueued_job(AssignNearestDriverJob)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("Delivery request created successfully")
      expect(body.dig("data", "status")).to eq("pending")
      expect(body.dig("data", "pickup_address", "city")).to eq("Nairobi")
    end

    it "accepts bearer token authentication from login" do
      expect {
        post "/api/v1/delivery_requests", params: params, headers: bearer_auth_headers(user)
      }.to have_enqueued_job(AssignNearestDriverJob)

      expect(response).to have_http_status(:created)
    end

    it "returns 422 when package_weight is invalid" do
      params[:delivery_request][:package_weight] = -1

      post "/api/v1/delivery_requests", params: params, headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "accepts county_id/country_id references and receiving-details fields" do
      kenya = create(:country, name: "Kenya")
      nairobi = create(:county, country: kenya, name: "Nairobi")
      params[:delivery_request][:delivery_address].merge!(
        county_id: nairobi.id,
        country_id: kenya.id,
        building_name: "ABC Place",
        floor: "3rd floor",
        door: "B12",
        instructions: "Call at the gate"
      )

      post "/api/v1/delivery_requests", params: params, headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:created)
      delivery_address = JSON.parse(response.body).dig("data", "delivery_address")
      expect(delivery_address.dig("county", "name")).to eq("Nairobi")
      expect(delivery_address.dig("country", "name")).to eq("Kenya")
      expect(delivery_address["building_name"]).to eq("ABC Place")
      expect(delivery_address["floor"]).to eq("3rd floor")
      expect(delivery_address["door"]).to eq("B12")
      expect(delivery_address["instructions"]).to eq("Call at the gate")
    end

    it "returns 422 (not a raw 500) for a county_id that does not exist" do
      params[:delivery_request][:delivery_address][:county_id] = SecureRandom.uuid

      post "/api/v1/delivery_requests", params: params, headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["success"]).to be false
      expect(body["errors"]).to include("field" => "county", "message" => "must exist", "code" => "required")
    end

    it "returns 422 (not a raw 500) for a country_id that does not exist" do
      params[:delivery_request][:pickup_address][:country_id] = SecureRandom.uuid

      post "/api/v1/delivery_requests", params: params, headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["success"]).to be false
      expect(body["errors"]).to include("field" => "country", "message" => "must exist", "code" => "required")
    end
  end

  describe "GET /api/v1/delivery_requests" do
    it "returns only the authenticated user's own requests, paginated" do
      mine = create(:delivery_request, user: user)
      create(:delivery_request) # someone else's

      get "/api/v1/delivery_requests", headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([mine.id])
      expect(body["meta"]).to include("current_page", "total_pages", "total_count")
    end

    it "returns the authenticated driver's assigned requests and rejected request history" do
      assigned = create(:delivery_request, driver: driver, status: :assigned)
      rejected = create(:delivery_request, status: :finding_driver)
      rejected.record_event!(:driver_rejected, driver_id: driver.id)
      create(:delivery_request) # unassigned

      get "/api/v1/delivery_requests", headers: basic_auth_headers(driver.email, "password123")

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to contain_exactly(assigned.id, rejected.id)
    end

    it "returns assigned requests using a driver bearer token" do
      mine = create(:delivery_request, driver: driver, status: :assigned)
      create(:delivery_request)

      get "/api/v1/delivery_requests", headers: bearer_auth_headers(driver)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([mine.id])
    end

    it "filters by status via ?status=" do
      pending_request = create(:delivery_request, user: user, status: :pending)
      create(:delivery_request, user: user, status: :delivered)

      get "/api/v1/delivery_requests", params: { status: "pending" },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([pending_request.id])
    end

    it "returns 400 for an unknown status filter" do
      get "/api/v1/delivery_requests", params: { status: "bogus" },
        headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body["success"]).to be false
    end

    it "searches package_description via ?q=" do
      match = create(:delivery_request, user: user, package_description: "Laptop charger")
      create(:delivery_request, user: user, package_description: "Books")

      get "/api/v1/delivery_requests", params: { q: "charger" },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([match.id])
    end

    it "searches pickup and delivery address fields via ?q=" do
      pickup_match = create(:delivery_request, user: user, pickup_address: create(:address, city: "Kisumu"))
      delivery_match = create(:delivery_request, user: user, delivery_address: create(:address, line1: "Mombasa Road"))
      create(:delivery_request, user: user, package_description: "Books")

      get "/api/v1/delivery_requests", params: { q: "mombasa" },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([delivery_match.id])

      get "/api/v1/delivery_requests", params: { q: "kisumu" },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([pickup_match.id])
    end

    it "filters by created_from and created_to" do
      older = create(:delivery_request, user: user)
      older.update_column(:created_at, 3.days.ago)
      in_range = create(:delivery_request, user: user)
      in_range.update_column(:created_at, 1.day.ago)
      newer = create(:delivery_request, user: user)

      get "/api/v1/delivery_requests",
        params: {
          created_from: 2.days.ago.iso8601,
          created_to: 12.hours.ago.iso8601
        },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([in_range.id])
      expect(body["data"].map { |d| d["id"] }).not_to include(older.id, newer.id)
    end

    it "filters by driver_id within the authenticated user's visible requests" do
      assigned_driver = create(:driver)
      matching = create(:delivery_request, user: user, driver: assigned_driver, status: :assigned)
      create(:delivery_request, user: user, driver: create(:driver), status: :assigned)

      get "/api/v1/delivery_requests", params: { driver_id: assigned_driver.id },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([matching.id])
    end

    it "sorts by an allowed field and direction" do
      light = create(:delivery_request, user: user, package_weight: 1.0)
      heavy = create(:delivery_request, user: user, package_weight: 9.0)

      get "/api/v1/delivery_requests",
        params: { sort_by: "package_weight", sort_direction: "asc" },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([light.id, heavy.id])
    end

    it "paginates with page and per_page" do
      requests = create_list(:delivery_request, 3, user: user)
      requests.each_with_index { |delivery_request, index| delivery_request.update_column(:created_at, index.hours.ago) }

      get "/api/v1/delivery_requests", params: { page: 2, per_page: 2 },
        headers: basic_auth_headers(user.email, "password123")

      body = JSON.parse(response.body)
      expect(body["data"].map { |d| d["id"] }).to eq([requests.third.id])
      expect(body["meta"]).to include("current_page" => 2, "total_pages" => 2, "total_count" => 3)
    end

    it "returns 400 for invalid sorting and pagination params" do
      get "/api/v1/delivery_requests", params: { sort_by: "user_id" },
        headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:bad_request)

      get "/api/v1/delivery_requests", params: { sort_direction: "sideways" },
        headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:bad_request)

      get "/api/v1/delivery_requests", params: { per_page: 101 },
        headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/v1/delivery_requests/:id" do
    let(:delivery_request) { create(:delivery_request, user: user) }

    it "is visible to the owning user" do
      get "/api/v1/delivery_requests/#{delivery_request.id}", headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a user who does not own it" do
      other_user = create(:user, password: "password123")

      get "/api/v1/delivery_requests/#{delivery_request.id}", headers: basic_auth_headers(other_user.email, "password123")

      expect(response).to have_http_status(:not_found)
    end

    it "is visible to a driver who previously rejected it" do
      rejected_request = create(:delivery_request, status: :finding_driver)
      rejected_request.record_event!(:driver_rejected, driver_id: driver.id)

      get "/api/v1/delivery_requests/#{rejected_request.id}", headers: basic_auth_headers(driver.email, "password123")

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/delivery_requests/:id/accept" do
    let(:delivery_request) { create(:delivery_request, driver: driver, status: :assigned) }

    it "accepts the request and sets the driver to on_delivery" do
      post "/api/v1/delivery_requests/#{delivery_request.id}/accept",
        headers: basic_auth_headers(driver.email, "password123")

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("Delivery request accepted")
      expect(body.dig("data", "status")).to eq("accepted")
      expect(driver.reload.status).to eq("on_delivery")
    end

    it "returns 404 (not 409) for a driver the request isn't assigned to, hiding existence" do
      other_driver = create(:driver, password: "password123")

      post "/api/v1/delivery_requests/#{delivery_request.id}/accept",
        headers: basic_auth_headers(other_driver.email, "password123")

      expect(response).to have_http_status(:not_found)
    end

    it "requires driver authentication, not user authentication" do
      post "/api/v1/delivery_requests/#{delivery_request.id}/accept",
        headers: basic_auth_headers(user.email, "password123")

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/delivery_requests/:id/reject" do
    let(:delivery_request) { create(:delivery_request, driver: driver, status: :assigned) }

    it "rejects the request, clears the driver, and re-enqueues assignment" do
      expect {
        post "/api/v1/delivery_requests/#{delivery_request.id}/reject",
          headers: basic_auth_headers(driver.email, "password123")
      }.to have_enqueued_job(AssignNearestDriverJob)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("Delivery request rejected")
      expect(body.dig("data", "status")).to eq("finding_driver")
      expect(body.dig("data", "driver")).to be_nil
    end

    it "returns 409 when the request is no longer in assigned status" do
      delivery_request.update!(status: :accepted)

      post "/api/v1/delivery_requests/#{delivery_request.id}/reject",
        headers: basic_auth_headers(driver.email, "password123")

      expect(response).to have_http_status(:conflict)
    end
  end
end
