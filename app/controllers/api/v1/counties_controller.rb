module Api
  module V1
    class CountiesController < ApplicationController
      # Reference data for populating address forms; no auth required to read it.

      def index
        counties = County.order(:name)
        counties = counties.where(country_id: params[:country_id]) if params[:country_id].present?

        render_success(
          data: counties.map { |county| CountySerializer.new(county).as_json },
          message: "Counties retrieved successfully"
        )
      end
    end
  end
end
