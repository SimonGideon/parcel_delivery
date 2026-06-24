class CountrySerializer
  def initialize(country)
    @country = country
  end

  def as_json(*_args)
    {
      id: country.id,
      name: country.name,
      iso2: country.iso2,
      iso3: country.iso3,
      phonecode: country.phonecode,
      capital: country.capital,
      currency: country.currency,
      currency_symbol: country.currency_symbol,
      region: country.region,
      latitude: country.latitude&.to_f,
      longitude: country.longitude&.to_f
    }
  end

  private

  attr_reader :country
end
