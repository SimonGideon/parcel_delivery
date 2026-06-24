module Api
  module V1
    class CountriesController < ApplicationController
      # Reference data for populating address forms; no auth required to read it.

      # ?q= searches by name (case-insensitive, partial match).
      def index
        countries = Country.order(:name)
        countries = countries.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
        countries = countries.page(params[:page]).per(params[:per_page] || 25)

        render_success(
          data: countries.map { |country| CountrySerializer.new(country).as_json },
          message: "Countries retrieved successfully",
          meta: pagination_meta(countries)
        )
      end
    end
  end
end
