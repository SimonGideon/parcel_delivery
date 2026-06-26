class Driver < User
  has_many :driver_locations, dependent: :destroy
  has_many :delivery_requests, foreign_key: :driver_id, inverse_of: :driver, dependent: :restrict_with_error

  enum :status, { available: 0, unavailable: 1, on_delivery: 2 }, default: :available

  before_validation :set_driver_role

  def current_location
    driver_locations.order(recorded_at: :desc).first
  end

  private

  def set_driver_role
    self.role = :driver
  end
end
