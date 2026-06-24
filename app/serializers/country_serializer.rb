class CountrySerializer
  def initialize(country)
    @country = country
  end

  def as_json(*_args)
    {
      id: country.id,
      name: country.name,
      code: country.code
    }
  end

  private

  attr_reader :country
end
