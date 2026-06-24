module Drivers
  class FindNearestAvailable
    def initialize(origin_coordinates:, exclude_driver_ids: [])
      @origin = origin_coordinates
      @exclude_driver_ids = exclude_driver_ids
    end

    def call
      return nil if latest_locations_by_driver_id.empty?

      nearest = latest_locations_by_driver_id.values.min_by { |location| distance_to(location) }
      Driver.find_by(id: nearest&.driver_id)
    end

    private

    attr_reader :origin, :exclude_driver_ids

    # One query for candidate driver ids, one query for their latest known location
    # (Postgres DISTINCT ON), instead of N+1 queries via driver.current_location.
    def latest_locations_by_driver_id
      @latest_locations_by_driver_id ||= begin
        driver_ids = Driver.available.where.not(id: exclude_driver_ids).pluck(:id)
        return {} if driver_ids.empty?

        DriverLocation
          .select("DISTINCT ON (driver_id) *")
          .where(driver_id: driver_ids)
          .order(:driver_id, recorded_at: :desc)
          .index_by(&:driver_id)
      end
    end

    def distance_to(location)
      Geo::Haversine.distance_km(origin, location.coordinates)
    end
  end
end
