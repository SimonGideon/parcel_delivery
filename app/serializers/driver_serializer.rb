class DriverSerializer
  def initialize(driver)
    @driver = driver
  end

  def as_json(*_args)
    {
      id: driver.id,
      name: driver.name,
      email: driver.email,
      phone: driver.phone,
      status: driver.status,
      created_at: driver.created_at.iso8601
    }
  end

  private

  attr_reader :driver
end
