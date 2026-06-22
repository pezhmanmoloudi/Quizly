require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  let(:user)        { create(:user) }
  let(:other_user)  { create(:user) }

  describe "#show?" do
    it "permits an authenticated user to view any profile" do
      policy = described_class.new(user, other_user)
      expect(policy.show?).to be(true)
    end

    it "permits a guest (nil user) to view a profile" do
      policy = described_class.new(nil, other_user)
      expect(policy.show?).to be(true)
    end
  end

  describe "Scope" do
    it "resolves to all users" do
      create_list(:user, 3)
      scope = described_class::Scope.new(user, User).resolve
      expect(scope.count).to eq(User.count)
    end
  end
end
