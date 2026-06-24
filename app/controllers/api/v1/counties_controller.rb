module Api
  module V1
    class CountiesController < ApplicationController
      # Reference data for populating address forms; no auth required to read it.

      # ?country_id= filters by country; ?q= searches by name (case-insensitive, partial match).
      def index
        counties = County.order(:name)
        counties = counties.where(country_id: params[:country_id]) if params[:country_id].present?
        counties = counties.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
        counties = counties.page(params[:page]).per(params[:per_page] || 25)

        render_success(
          data: counties.map { |county| CountySerializer.new(county).as_json },
          message: "Counties retrieved successfully",
          meta: pagination_meta(counties)
        )
      end
    end
  end
end
