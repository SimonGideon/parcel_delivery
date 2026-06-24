require "rails_helper"

RSpec.describe Driver, type: :model do
  it "is valid with a name, unique email, and password" do
    expect(build(:driver)).to be_valid
  end

  it "defaults to available status" do
    expect(create(:driver).status).to eq("available")
  end

  it "requires a unique email, case-insensitively" do
    create(:driver, email: "taken@example.com")
    expect(build(:driver, email: "TAKEN@example.com")).not_to be_valid
  end

  it "authenticates with the correct password via has_secure_password" do
    driver = create(:driver, password: "correct-password")
    expect(driver.authenticate("correct-password")).to eq(driver)
    expect(driver.authenticate("wrong-password")).to be false
  end

  describe "#current_location" do
    it "returns nil when the driver has no recorded location" do
      expect(create(:driver).current_location).to be_nil
    end

    it "returns the most recently recorded location" do
      driver = create(:driver)
      older = create(:driver_location, driver: driver, recorded_at: 1.hour.ago)
      newer = create(:driver_location, driver: driver, recorded_at: 1.minute.ago)

      expect(driver.current_location).to eq(newer)
      expect(driver.current_location).not_to eq(older)
    end
  end
end
