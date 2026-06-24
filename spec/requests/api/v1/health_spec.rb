require "swagger_helper"

RSpec.describe "api/v1/health", type: :request do
  path "/api/v1/health" do
    get "Checks API and database health" do
      tags "Health"
      produces "application/json"

      response "200", "service is healthy" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 database: { type: :string, example: "connected" },
                 timestamp: { type: :string, format: "date-time" }
               },
               required: %w[status database timestamp]

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["status"]).to eq("ok")
        end
      end
    end
  end
end
