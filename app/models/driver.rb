class Driver < ApplicationRecord
  has_secure_password

  has_many :driver_locations, dependent: :destroy
  has_many :delivery_requests, dependent: :restrict_with_error

  enum :status, { available: 0, unavailable: 1, on_delivery: 2 }, default: :available

  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_FORMAT }

  before_save { email&.downcase! }

  def current_location
    driver_locations.order(recorded_at: :desc).first
  end
end
