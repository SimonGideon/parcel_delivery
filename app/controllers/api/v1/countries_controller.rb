module Api
  module V1
    class CountriesController < ApplicationController
      # Reference data for populating address forms; no auth required to read it.

      def index
        countries = Country.order(:name)
        render_success(
          data: countries.map { |country| CountrySerializer.new(country).as_json },
          message: "Countries retrieved successfully"
        )
      end
    end
  end
end
