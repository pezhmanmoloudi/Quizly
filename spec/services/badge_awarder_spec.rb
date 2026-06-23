require "rails_helper"

RSpec.describe BadgeAwarder, type: :service do
  let(:user) { create(:user) }

  def seed_badge(key, category: "streak")
    Badge.find_or_create_by!(key: key) do |b|
      b.name        = key.humanize
      b.description = "desc"
      b.icon        = "🏅"
      b.category    = category
    end
  end

  describe ".call" do
    context "first_session badge" do
      let!(:badge) { seed_badge("first_session") }
      let(:deck)   { create(:deck, user: user) }

      it "awards the badge when the user has completed at least one session" do
        create(:study_session, :completed, user: user, deck: deck)
        expect { BadgeAwarder.call(user) }.to change { user.user_badges.count }.by(1)
        expect(user.badges.pluck(:key)).to include("first_session")
      end

      it "does not re-award an already-earned badge" do
        create(:study_session, :completed, user: user, deck: deck)
        BadgeAwarder.call(user)
        expect { BadgeAwarder.call(user) }.not_to change { user.user_badges.count }
      end
    end

    context "streak_3 badge" do
      let!(:badge) { seed_badge("streak_3") }

      it "awards when current_streak >= 3" do
        user.update_columns(current_streak: 3)
        expect { BadgeAwarder.call(user) }.to change { user.user_badges.count }.by(1)
      end

      it "does not award when current_streak < 3" do
        user.update_columns(current_streak: 2)
        expect { BadgeAwarder.call(user) }.not_to change { user.user_badges.count }
      end
    end

    context "cards_100 badge" do
      let!(:badge) { seed_badge("cards_100", category: "cards") }
      let(:deck)   { create(:deck, user: user) }

      it "awards when total cards reviewed >= 100" do
        create(:study_session, :completed, user: user, deck: deck, cards_reviewed: 60)
        create(:study_session, :completed, user: user, deck: deck, cards_reviewed: 50)
        expect { BadgeAwarder.call(user) }.to change { user.user_badges.count }.by(1)
      end

      it "does not award when total cards reviewed < 100" do
        create(:study_session, :completed, user: user, deck: deck, cards_reviewed: 50)
        expect { BadgeAwarder.call(user) }.not_to change { user.user_badges.count }
      end
    end

    context "perfect_test badge" do
      let!(:badge) { seed_badge("perfect_test", category: "accuracy") }
      let(:deck)   { create(:deck, user: user) }

      it "awards when a test session has score == questions_total" do
        create(:test_session, :completed, user: user, deck: deck, score: 5, questions_total: 5)
        expect { BadgeAwarder.call(user) }.to change { user.user_badges.count }.by(1)
      end

      it "does not award when no perfect test exists" do
        create(:test_session, :completed, user: user, deck: deck, score: 4, questions_total: 5)
        expect { BadgeAwarder.call(user) }.not_to change { user.user_badges.count }
      end
    end

    it "returns an array of newly-awarded Badge records" do
      seed_badge("streak_3")
      user.update_columns(current_streak: 3)
      result = BadgeAwarder.call(user)
      expect(result.map(&:key)).to include("streak_3")
    end

    it "returns an empty array when no new badges are earned" do
      expect(BadgeAwarder.call(user)).to eq([])
    end

    it "creates a badge_earned notification for each newly awarded badge" do
      seed_badge("streak_3")
      user.update_columns(current_streak: 3)
      expect { BadgeAwarder.call(user) }
        .to change { user.notifications.where(event_type: "badge_earned").count }.by(1)
    end
  end
end
