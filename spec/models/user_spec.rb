require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with a name, unique email, and password" do
    expect(build(:user)).to be_valid
  end

  it "requires a name" do
    expect(build(:user, name: nil)).not_to be_valid
  end

  it "requires a unique email, case-insensitively" do
    create(:user, email: "taken@example.com")
    expect(build(:user, email: "TAKEN@example.com")).not_to be_valid
  end

  it "downcases email before save" do
    user = create(:user, email: "MixedCase@Example.com")
    expect(user.reload.email).to eq("mixedcase@example.com")
  end

  it "authenticates with the correct password via has_secure_password" do
    user = create(:user, password: "correct-password")
    expect(user.authenticate("correct-password")).to eq(user)
    expect(user.authenticate("wrong-password")).to be false
  end

  it "has many delivery_requests" do
    expect(User.reflect_on_association(:delivery_requests).macro).to eq(:has_many)
  end
end
