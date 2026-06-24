class DriverLocationSerializer
  def initialize(location)
    @location = location
  end

  def as_json(*_args)
    {
      id: location.id,
      driver_id: location.driver_id,
      latitude: location.latitude.to_f,
      longitude: location.longitude.to_f,
      recorded_at: location.recorded_at.iso8601
    }
  end

  private

  attr_reader :location
end
