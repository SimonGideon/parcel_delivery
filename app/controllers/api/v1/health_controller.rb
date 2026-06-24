module Api
  module V1
    class HealthController < ApplicationController
      def show
        ActiveRecord::Base.connection.execute("SELECT 1")
        render json: { status: "ok", database: "connected", timestamp: Time.current.iso8601 }
      rescue StandardError => e
        render json: { status: "error", database: "unavailable", error: e.message }, status: :service_unavailable
      end
    end
  end
end
