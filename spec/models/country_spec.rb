require "rails_helper"

RSpec.describe Country, type: :model do
  it "is valid with a unique name" do
    expect(build(:country)).to be_valid
  end

  it "requires a name" do
    expect(build(:country, name: nil)).not_to be_valid
  end

  it "requires a unique name" do
    create(:country, name: "Kenya")
    expect(build(:country, name: "Kenya")).not_to be_valid
  end

  it "restricts deletion when counties exist" do
    country = create(:country)
    create(:county, country: country)

    expect { country.destroy }.not_to change(Country, :count)
    expect(country.errors[:base]).to be_present
  end
end
