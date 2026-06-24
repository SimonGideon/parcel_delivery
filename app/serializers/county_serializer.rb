class CountySerializer
  def initialize(county)
    @county = county
  end

  def as_json(*_args)
    {
      id: county.id,
      name: county.name,
      country_id: county.country_id
    }
  end

  private

  attr_reader :county
end
