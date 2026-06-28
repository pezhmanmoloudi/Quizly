require "rails_helper"

RSpec.describe UserBadge, type: :model do
  let(:user)  { create(:user) }
  let(:badge) { create(:badge) }

  describe "validations" do
    it "is valid with valid attributes" do
      user_badge = build(:user_badge, user: user, badge: badge)
      expect(user_badge).to be_valid
    end

    it "is invalid without earned_at" do
      user_badge = build(:user_badge, user: user, badge: badge, earned_at: nil)
      expect(user_badge).not_to be_valid
    end

    it "rejects the same badge awarded twice to the same user" do
      create(:user_badge, user: user, badge: badge)
      duplicate = build(:user_badge, user: user, badge: badge)
      expect(duplicate).not_to be_valid
    end

    it "allows the same badge to be awarded to different users" do
      other_user = create(:user)
      create(:user_badge, user: user, badge: badge)
      second = build(:user_badge, user: other_user, badge: badge)
      expect(second).to be_valid
    end

    it "allows the same user to earn different badges" do
      other_badge = create(:badge)
      create(:user_badge, user: user, badge: badge)
      second = build(:user_badge, user: user, badge: other_badge)
      expect(second).to be_valid
    end
  end

  describe "associations" do
    it "belongs to user" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to badge" do
      association = described_class.reflect_on_association(:badge)
      expect(association.macro).to eq(:belongs_to)
    end
  end
end
