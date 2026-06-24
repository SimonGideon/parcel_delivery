module Geo
  # Great-circle distance between two [lat, lng] coordinates, in kilometers.
  module Haversine
    EARTH_RADIUS_KM = 6371.0

    module_function

    def distance_km(coord_a, coord_b)
      lat1, lon1 = coord_a.map { |v| to_radians(v) }
      lat2, lon2 = coord_b.map { |v| to_radians(v) }

      delta_lat = lat2 - lat1
      delta_lon = lon2 - lon1

      a = Math.sin(delta_lat / 2)**2 +
          Math.cos(lat1) * Math.cos(lat2) * Math.sin(delta_lon / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      EARTH_RADIUS_KM * c
    end

    def to_radians(degrees)
      degrees.to_f * Math::PI / 180
    end
  end
end
