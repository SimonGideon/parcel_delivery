class Address < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :county, optional: true

  validates :line1, :city, presence: true
  validates :latitude, presence: true,
    numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validate :county_must_exist
  validate :country_must_exist
  validate :county_belongs_to_country

  def coordinates
    [latitude.to_f, longitude.to_f]
  end

  private

  # county/country are optional, but if an id IS given it must refer to a real
  # row -- otherwise this would only surface as a raw DB foreign key violation
  # (500) at save time instead of a normal validation error.
  def county_must_exist
    errors.add(:county, :required) if county_id.present? && county.nil?
  end

  def country_must_exist
    errors.add(:country, :required) if country_id.present? && country.nil?
  end

  def county_belongs_to_country
    return unless county && country && county.country_id != country.id

    errors.add(:county, "does not belong to the selected country")
  end
end
