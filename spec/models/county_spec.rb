require "rails_helper"

RSpec.describe County, type: :model do
  it "is valid with a country and a name" do
    expect(build(:county)).to be_valid
  end

  it "requires a country" do
    expect(build(:county, country: nil)).not_to be_valid
  end

  it "requires a name unique within its country" do
    country = create(:country)
    create(:county, country: country, name: "Nairobi")

    expect(build(:county, country: country, name: "Nairobi")).not_to be_valid
  end

  it "allows the same name in two different countries" do
    create(:county, name: "Nairobi", country: create(:country))

    expect(build(:county, name: "Nairobi", country: create(:country))).to be_valid
  end
end
