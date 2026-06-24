class AddressSerializer
  def initialize(address)
    @address = address
  end

  def as_json(*_args)
    {
      id: address.id,
      line1: address.line1,
      line2: address.line2,
      city: address.city,
      county: address.county,
      nearest_town: address.nearest_town,
      postal_code: address.postal_code,
      country: address.country,
      latitude: address.latitude.to_f,
      longitude: address.longitude.to_f
    }
  end

  private

  attr_reader :address
end
