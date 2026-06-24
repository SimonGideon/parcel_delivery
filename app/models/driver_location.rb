class DriverLocation < ApplicationRecord
  belongs_to :driver

  validates :latitude, presence: true,
    numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :recorded_at, presence: true

  before_validation { self.recorded_at ||= Time.current }

  def coordinates
    [latitude.to_f, longitude.to_f]
  end
end
