require "rails_helper"

RSpec.describe FollowPolicy, type: :policy do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }
  let(:follow)   { build(:follow, follower: follower, followed: followed) }

  describe "#create?" do
    it "permits an authenticated user to follow another user" do
      policy = described_class.new(follower, follow)
      expect(policy.create?).to be(true)
    end

    it "denies a guest (nil user)" do
      policy = described_class.new(nil, follow)
      expect(policy.create?).to be(false)
    end

    it "denies a user following themselves" do
      self_follow = build(:follow, follower: follower, followed: follower)
      policy = described_class.new(follower, self_follow)
      expect(policy.create?).to be(false)
    end
  end

  describe "#destroy?" do
    it "permits the follower to destroy their own follow" do
      policy = described_class.new(follower, follow)
      expect(policy.destroy?).to be(true)
    end

    it "denies a different authenticated user" do
      other = create(:user)
      policy = described_class.new(other, follow)
      expect(policy.destroy?).to be(false)
    end

    it "denies a guest (nil user)" do
      policy = described_class.new(nil, follow)
      expect(policy.destroy?).to be(false)
    end
  end

  describe "Scope" do
    it "returns only follows where the current user is the follower" do
      own_follow   = create(:follow, follower: follower, followed: followed)
      other_follow = create(:follow, follower: followed, followed: follower)

      scope = described_class::Scope.new(follower, Follow).resolve
      expect(scope).to include(own_follow)
      expect(scope).not_to include(other_follow)
    end
  end
end
