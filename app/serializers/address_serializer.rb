class AddressSerializer
  def initialize(address)
    @address = address
  end

  def as_json(*_args)
    {
      line1: address.line1,
      line2: address.line2,
      city: address.city,
      county: county_summary,
      nearest_town: address.nearest_town,
      building_name: address.building_name,
      floor: address.floor,
      door: address.door,
      instructions: address.instructions,
      postal_code: address.postal_code,
      country: country_summary,
      latitude: address.latitude.to_f,
      longitude: address.longitude.to_f
    }
  end

  private

  attr_reader :address

  def county_summary
    return nil unless address.county_id

    { id: address.county_id, name: address.county&.name }
  end

  def country_summary
    return nil unless address.country_id

    { id: address.country_id, name: address.country&.name }
  end
end
