require "rails_helper"
require "cancan/matchers"

RSpec.describe Ability, type: :model do
  subject(:ability) { described_class.new(principal) }

  context "when the principal is a customer" do
    let(:principal) { create(:user) }
    let(:own_request) { create(:delivery_request, user: principal) }
    let(:other_request) { create(:delivery_request) }

    it { is_expected.to be_able_to(:create, DeliveryRequest) }
    it { is_expected.to be_able_to(:read, own_request) }
    it { is_expected.not_to be_able_to(:read, other_request) }
    it { is_expected.not_to be_able_to(:accept, own_request) }
    it { is_expected.not_to be_able_to(:create, DriverLocation) }
  end

  context "when the principal is a driver" do
    let(:principal) { create(:driver) }
    let(:assigned_request) { create(:delivery_request, driver: principal, status: :assigned) }
    let(:rejected_request) do
      create(:delivery_request, status: :finding_driver).tap do |delivery_request|
        delivery_request.record_event!(:driver_rejected, driver_id: principal.id)
      end
    end
    let(:other_request) { create(:delivery_request) }

    it { is_expected.to be_able_to(:read, assigned_request) }
    it { is_expected.to be_able_to(:read, rejected_request) }
    it { is_expected.to be_able_to(:accept, assigned_request) }
    it { is_expected.to be_able_to(:reject, assigned_request) }
    it { is_expected.to be_able_to(:create, DriverLocation) }
    it { is_expected.not_to be_able_to(:read, other_request) }
    it { is_expected.not_to be_able_to(:create, DeliveryRequest) }
  end

  context "when there is no principal" do
    let(:principal) { nil }

    it { is_expected.not_to be_able_to(:read, DeliveryRequest) }
    it { is_expected.not_to be_able_to(:create, DeliveryRequest) }
    it { is_expected.not_to be_able_to(:create, DriverLocation) }
  end
end
