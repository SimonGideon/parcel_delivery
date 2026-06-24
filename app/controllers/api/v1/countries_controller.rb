module Api
  module V1
    class CountriesController < ApplicationController
      # Reference data for populating address forms; no auth required to read it.

      def index
        countries = Country.order(:name)
        render json: { data: countries.map { |country| CountrySerializer.new(country).as_json } }
      end
    end
  end
end
