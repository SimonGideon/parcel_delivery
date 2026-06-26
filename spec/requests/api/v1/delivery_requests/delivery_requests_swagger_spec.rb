require "swagger_helper"

RSpec.describe "api/v1/delivery_requests", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:driver) { create(:driver, password: "password123", status: :available) }
  let(:user_auth) { "Bearer #{AuthToken.issue(user)}" }
  let(:driver_auth) { "Bearer #{AuthToken.issue(driver)}" }

  address_schema = {
    type: :object,
    properties: {
      line1: { type: :string, example: "123 Main St" },
      line2: { type: :string, nullable: true },
      city: { type: :string, example: "Nairobi" },
      county: {
        type: :object, nullable: true,
        properties: { id: { type: :string, format: :uuid }, name: { type: :string, example: "Nairobi" } }
      },
      nearest_town: { type: :string, nullable: true, example: "Near Total Petrol Station, Ruiru" },
      building_name: { type: :string, nullable: true, example: "ABC Place" },
      floor: { type: :string, nullable: true, example: "3rd floor" },
      door: { type: :string, nullable: true, example: "B12" },
      instructions: { type: :string, nullable: true, example: "Call at the gate" },
      postal_code: { type: :string, nullable: true },
      country: {
        type: :object, nullable: true,
        properties: { id: { type: :string, format: :uuid }, name: { type: :string, example: "Kenya" } }
      },
      latitude: { type: :number, example: 1.2945 },
      longitude: { type: :number, example: 36.8228 }
    }
  }.freeze

  delivery_request_schema = {
    type: :object,
    properties: {
      id: { type: :string, format: :uuid },
      status: {
        type: :string,
        enum: %w[pending finding_driver assigned accepted picked_up in_transit delivered cancelled],
        example: "pending"
      },
      package_description: { type: :string, example: "Books" },
      package_weight: { type: :number, example: 2.5 },
      pickup_address: address_schema,
      delivery_address: address_schema,
      user: {
        type: :object,
        properties: { id: { type: :string, format: :uuid }, name: { type: :string, example: "Alice" } }
      },
      driver: {
        type: :object, nullable: true,
        properties: { id: { type: :string, format: :uuid }, name: { type: :string, example: "Bob" } }
      },
      created_at: { type: :string, format: "date-time" },
      updated_at: { type: :string, format: "date-time" }
    }
  }.freeze

  # Builds the standard { success, message, data, meta } success envelope.
  success_envelope = lambda do |message_example, data_schema|
    {
      type: :object,
      properties: {
        success: { type: :boolean, example: true },
        message: { type: :string, example: message_example },
        data: data_schema,
        meta: { type: :object, nullable: true, example: nil }
      },
      required: %w[success message data meta]
    }
  end

  # Builds the standard { success, message, errors } error envelope.
  error_envelope = lambda do |message_example|
    {
      type: :object,
      properties: {
        success: { type: :boolean, example: false },
        message: { type: :string, example: message_example },
        errors: { type: :array, items: { type: :object }, example: [] }
      },
      required: %w[success message errors]
    }
  end

  delivery_request_list_meta_schema = {
    type: :object,
    properties: {
      current_page: { type: :integer, example: 1 },
      next_page: { type: :integer, nullable: true },
      prev_page: { type: :integer, nullable: true },
      total_pages: { type: :integer, example: 1 },
      total_count: { type: :integer, example: 1 },
      filters: {
        type: :object,
        properties: {
          allowed_statuses: {
            type: :array,
            items: { type: :string },
            example: %w[finding_driver assigned accepted picked_up in_transit delivered cancelled]
          }
        }
      }
    }
  }.freeze

  delivery_request_list_schema = {
    type: :object,
    properties: {
      success: { type: :boolean, example: true },
      message: { type: :string, example: "Delivery requests retrieved successfully" },
      data: { type: :array, items: delivery_request_schema },
      meta: delivery_request_list_meta_schema
    },
    required: %w[success message data meta]
  }.freeze

  shared_list_query_parameters = lambda do
    parameter name: :status, in: :query, required: false,
      schema: { type: :string },
      description: <<~DESC.squish
        Filter by lifecycle status. Allowed values are role-specific and are
        returned in meta.filters.allowed_statuses. Customer tokens may filter
        all lifecycle statuses; driver tokens may filter only driver-visible
        statuses.
      DESC
    parameter name: :driver_id, in: :query, required: false,
      schema: { type: :string, format: :uuid },
      description: "Filter visible requests by assigned driver id"
    parameter name: :created_from, in: :query, required: false,
      schema: { type: :string, format: "date-time" },
      description: "Filter requests created at or after this ISO8601 timestamp"
    parameter name: :created_to, in: :query, required: false,
      schema: { type: :string, format: "date-time" },
      description: "Filter requests created at or before this ISO8601 timestamp"
    parameter name: :q, in: :query, required: false,
      schema: { type: :string },
      description: "Search package_description plus pickup/delivery city, nearest_town, and line1"
    parameter name: :sort_by, in: :query, required: false,
      schema: { type: :string, enum: %w[created_at updated_at status package_weight] },
      description: "Sort field. Defaults to created_at"
    parameter name: :sort_direction, in: :query, required: false,
      schema: { type: :string, enum: %w[asc desc] },
      description: "Sort direction. Defaults to desc"
    parameter name: :page, in: :query, required: false,
      schema: { type: :integer },
      description: "Page number, starting at 1"
    parameter name: :per_page, in: :query, required: false,
      schema: { type: :integer },
      description: "Items per page, 1-100. Defaults to 25"
  end

  path "/api/v1/customer/delivery_requests" do
    get "Lists the authenticated customer's delivery requests" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]
      description "Customer-only list endpoint. Driver tokens are rejected."

      instance_exec(&shared_list_query_parameters)

      response "200", "customer requests returned" do
        schema delivery_request_list_schema

        let(:Authorization) { user_auth }
        before { create(:delivery_request, user: user) }
        run_test!
      end

      response "401", "driver token is not accepted" do
        schema error_envelope.call("Invalid credentials for this endpoint")

        let(:Authorization) { driver_auth }
        run_test!
      end
    end
  end

  path "/api/v1/driver/delivery_requests" do
    get "Lists the authenticated driver's request queue and history" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]
      description "Driver-only list endpoint. Customer tokens are rejected."

      instance_exec(&shared_list_query_parameters)

      response "200", "driver requests returned" do
        schema delivery_request_list_schema

        let(:Authorization) { driver_auth }
        before { create(:delivery_request, driver: driver, status: :assigned) }
        run_test!
      end

      response "401", "customer token is not accepted" do
        schema error_envelope.call("Invalid credentials for this endpoint")

        let(:Authorization) { user_auth }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests" do
    post "Creates a delivery request and triggers nearest-driver search" do
      tags "Delivery Requests"
      consumes "application/json"
      produces "application/json"
      security [{ bearer_auth: [] }]
      description <<~DESC
        Requires a **customer** bearer token. Register via POST /api/v1/users,
        log in via POST /api/v1/login, then paste the returned token into
        Swagger Authorize. Driver tokens will not work on this endpoint.
      DESC

      parameter name: :delivery_request, in: :body, schema: {
        type: :object,
        properties: {
          delivery_request: {
            type: :object,
            properties: {
              package_description: { type: :string, example: "Books" },
              package_weight: { type: :number, example: 2.5 },
              pickup_address: {
                type: :object,
                properties: {
                  line1: { type: :string, example: "123 Main St" },
                  city: { type: :string, example: "Nairobi" },
                  county_id: { type: :string, format: :uuid, nullable: true },
                  country_id: { type: :string, format: :uuid, nullable: true },
                  nearest_town: { type: :string, example: "Near Total Petrol Station, Ruiru" },
                  building_name: { type: :string, example: "ABC Place", nullable: true },
                  floor: { type: :string, example: "3rd floor", nullable: true },
                  door: { type: :string, example: "B12", nullable: true },
                  instructions: { type: :string, example: "Call at the gate", nullable: true },
                  latitude: { type: :number, example: 1.2945 },
                  longitude: { type: :number, example: 36.8228 }
                },
                required: %w[line1 city latitude longitude]
              },
              delivery_address: {
                type: :object,
                properties: {
                  line1: { type: :string, example: "456 Side St" },
                  city: { type: :string, example: "Nairobi" },
                  county_id: { type: :string, format: :uuid, nullable: true },
                  country_id: { type: :string, format: :uuid, nullable: true },
                  nearest_town: { type: :string, example: "Near Garden City Mall" },
                  building_name: { type: :string, example: "ABC Place", nullable: true },
                  floor: { type: :string, example: "3rd floor", nullable: true },
                  door: { type: :string, example: "B12", nullable: true },
                  instructions: { type: :string, example: "Call at the gate", nullable: true },
                  latitude: { type: :number, example: 1.3 },
                  longitude: { type: :number, example: 36.83 }
                },
                required: %w[line1 city latitude longitude]
              }
            },
            required: %w[package_description package_weight pickup_address delivery_address]
          }
        }
      }

      response "201", "delivery request created" do
        schema success_envelope.call("Delivery request created successfully", delivery_request_schema)

        let(:Authorization) { user_auth }
        let(:delivery_request) do
          {
            delivery_request: {
              package_description: "Books",
              package_weight: 2.5,
              pickup_address: { line1: "123 Main St", city: "Nairobi", latitude: 1.2945, longitude: 36.8228 },
              delivery_address: { line1: "456 Side St", city: "Nairobi", latitude: 1.3, longitude: 36.83 }
            }
          }
        end
        run_test!
      end

      response "422", "validation failed (e.g. a county_id/country_id that does not exist)" do
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string, example: "Validation failed" },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       field: { type: :string, example: "county" },
                       message: { type: :string, example: "must exist" },
                       code: { type: :string, example: "required" }
                     }
                   }
                 }
               },
               required: %w[success message errors]

        let(:Authorization) { user_auth }
        let(:delivery_request) do
          {
            delivery_request: {
              package_description: "Books",
              package_weight: 2.5,
              pickup_address: { line1: "123 Main St", city: "Nairobi", latitude: 1.2945, longitude: 36.8228 },
              delivery_address: {
                line1: "456 Side St", city: "Nairobi", latitude: 1.3, longitude: 36.83,
                county_id: SecureRandom.uuid
              }
            }
          }
        end
        run_test!
      end

      response "401", "missing or invalid credentials" do
        schema error_envelope.call("Missing Authorization header — log in and use the returned bearer token in Swagger")

        let(:Authorization) { "" }
        let(:delivery_request) do
          {
            delivery_request: {
              package_description: "Books",
              package_weight: 2.5,
              pickup_address: { line1: "123 Main St", city: "Nairobi", latitude: 1.2945, longitude: 36.8228 },
              delivery_address: { line1: "456 Side St", city: "Nairobi", latitude: 1.3, longitude: 36.83 }
            }
          }
        end
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}" do
    get "Retrieves a delivery request visible to its owner or assigned driver" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]

      parameter name: :id, in: :path, required: true, schema: { type: :string, format: :uuid }

      response "200", "delivery request found" do
        schema success_envelope.call("Delivery request retrieved successfully", delivery_request_schema)

        let(:Authorization) { user_auth }
        let(:id) { create(:delivery_request, user: user).id }
        run_test!
      end

      response "404", "not visible to this principal" do
        schema error_envelope.call("Couldn't find DeliveryRequest")

        let(:Authorization) { user_auth }
        let(:id) { create(:delivery_request).id }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}/cancel" do
    post "Customer cancels a delivery request before pickup" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]
      description "Customer-only action. Requests can be cancelled while pending, finding_driver, assigned, or accepted."

      parameter name: :id, in: :path, required: true, schema: { type: :string, format: :uuid }

      response "200", "request cancelled" do
        schema success_envelope.call("Delivery request cancelled", delivery_request_schema)

        let(:Authorization) { user_auth }
        let(:id) { create(:delivery_request, user: user, status: :assigned, driver: driver).id }
        run_test!
      end

      response "409", "request has already been picked up" do
        schema error_envelope.call("Delivery request cannot be cancelled from status 'picked_up'")

        let(:Authorization) { user_auth }
        let(:id) { create(:delivery_request, user: user, status: :picked_up, driver: driver).id }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}/accept" do
    post "Driver accepts an assigned delivery request" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]

      parameter name: :id, in: :path, required: true, schema: { type: :string, format: :uuid }

      response "200", "request accepted" do
        schema success_envelope.call("Delivery request accepted", delivery_request_schema)

        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :assigned).id }
        run_test!
      end

      response "409", "request is not in assigned status" do
        schema error_envelope.call("Delivery request cannot be accepted from status 'accepted'")

        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :accepted).id }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}/pick_up" do
    post "Driver marks an accepted delivery request as picked up" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]

      parameter name: :id, in: :path, required: true, schema: { type: :string, format: :uuid }

      response "200", "request picked up" do
        schema success_envelope.call("Delivery request picked up", delivery_request_schema)

        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :accepted).id }
        run_test!
      end

      response "409", "request has not been accepted" do
        schema error_envelope.call("Delivery request cannot be picked up from status 'assigned'")

        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :assigned).id }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}/deliver" do
    post "Driver marks a picked-up delivery request as delivered" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]

      parameter name: :id, in: :path, required: true, schema: { type: :string, format: :uuid }

      response "200", "request delivered" do
        schema success_envelope.call("Delivery request delivered", delivery_request_schema)

        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :picked_up).id }
        run_test!
      end

      response "409", "request has not been picked up" do
        schema error_envelope.call("Delivery request cannot be delivered from status 'accepted'")

        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :accepted).id }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_requests/{id}/reject" do
    post "Driver rejects an assigned delivery request, triggering re-assignment" do
      tags "Delivery Requests"
      produces "application/json"
      security [{ bearer_auth: [] }]

      parameter name: :id, in: :path, required: true, schema: { type: :string, format: :uuid }

      response "200", "request rejected" do
        schema success_envelope.call("Delivery request rejected", delivery_request_schema)

        let(:Authorization) { driver_auth }
        let(:id) { create(:delivery_request, driver: driver, status: :assigned).id }
        run_test!
      end
    end
  end
end
