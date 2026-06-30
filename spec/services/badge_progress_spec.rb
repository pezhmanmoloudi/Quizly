require "rails_helper"

RSpec.describe BadgeProgress do
  let(:user) { create(:user, current_streak: 3) }

  describe ".preview_for" do
    it "returns the fixed dashboard badge set in order" do
      BadgeProgress::DASHBOARD_KEYS.each { |key| create(:badge, key: key) }

      keys = described_class.preview_for(user).map { |e| e.badge.key }

      expect(keys).to eq(BadgeProgress::DASHBOARD_KEYS)
    end

    it "skips dashboard keys that have no seeded badge" do
      create(:badge, key: "streak_7")

      keys = described_class.preview_for(user).map { |e| e.badge.key }

      expect(keys).to eq(%w[streak_7])
    end

    it "marks earned badges and reports full progress" do
      badge = create(:badge, key: "streak_7")
      create(:user_badge, user: user, badge: badge)

      entry = described_class.preview_for(user).first

      expect(entry).to be_earned
      expect(entry.percent).to eq(100)
    end

    it "computes progress for unearned, metric-based badges" do
      create(:badge, key: "streak_7") # target 7, current_streak 3

      entry = described_class.preview_for(user).first

      expect(entry).not_to be_earned
      expect(entry.current).to eq(3)
      expect(entry.target).to eq(7)
      expect(entry.percent).to eq(43)
    end
  end
end
