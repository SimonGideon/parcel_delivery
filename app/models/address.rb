class Address < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :county, optional: true

  validates :line1, :city, presence: true
  validates :latitude, presence: true,
    numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validate :county_belongs_to_country

  def coordinates
    [latitude.to_f, longitude.to_f]
  end

  private

  def county_belongs_to_country
    return unless county && country && county.country_id != country.id

    errors.add(:county, "does not belong to the selected country")
  end
end
