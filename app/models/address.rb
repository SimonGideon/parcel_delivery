class Address < ApplicationRecord
  validates :line1, :city, presence: true
  validates :latitude, presence: true,
    numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  def coordinates
    [latitude.to_f, longitude.to_f]
  end
end
