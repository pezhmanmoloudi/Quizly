require "rails_helper"

RSpec.describe BadgeProgress do
  let(:user) { create(:user, current_streak: 3) }

  describe ".preview_for" do
    it "marks earned badges, lists them first, and reports full progress" do
      earned_badge = create(:badge, key: "streak_3")
      create(:badge, key: "streak_100")
      create(:user_badge, user: user, badge: earned_badge)

      entries = described_class.preview_for(user)

      expect(entries.first.badge).to eq(earned_badge)
      expect(entries.first).to be_earned
      expect(entries.first.percent).to eq(100)
    end

    it "computes progress for unearned, metric-based badges" do
      create(:badge, key: "streak_7") # target 7, current_streak 3

      entry = described_class.preview_for(user).find { |e| e.badge.key == "streak_7" }

      expect(entry).not_to be_earned
      expect(entry.current).to eq(3)
      expect(entry.target).to eq(7)
      expect(entry.percent).to eq(43)
    end

    it "orders unearned badges by closest to completion" do
      create(:badge, key: "streak_7")   # ~43%
      create(:badge, key: "streak_100") # ~3%

      keys = described_class.preview_for(user).reject(&:earned?).map { |e| e.badge.key }

      expect(keys.first).to eq("streak_7")
    end

    it "limits the preview to six entries" do
      %w[streak_3 streak_7 streak_30 streak_100 cards_10 cards_100 cards_500].each do |key|
        create(:badge, key: key)
      end

      expect(described_class.preview_for(user).size).to eq(6)
    end

    it "falls back to zero progress for badges without a definition" do
      create(:badge, key: "mystery_badge")

      entry = described_class.preview_for(user).find { |e| e.badge.key == "mystery_badge" }

      expect(entry.target).to eq(1)
      expect(entry.percent).to eq(0)
    end
  end
end
