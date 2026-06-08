require "rails_helper"

RSpec.describe StreakUpdater, type: :service do
  let(:user) { create(:user) }

  describe ".call" do
    context "first ever session" do
      it "sets current_streak to 1" do
        StreakUpdater.call(user)
        expect(user.reload.current_streak).to eq(1)
      end

      it "sets longest_streak to 1" do
        StreakUpdater.call(user)
        expect(user.reload.longest_streak).to eq(1)
      end

      it "sets last_studied_on to today" do
        StreakUpdater.call(user)
        expect(user.reload.last_studied_on).to eq(Date.current)
      end
    end

    context "studied yesterday" do
      before { user.update_columns(current_streak: 3, longest_streak: 5, last_studied_on: Date.current - 1) }

      it "increments current_streak" do
        StreakUpdater.call(user)
        expect(user.reload.current_streak).to eq(4)
      end

      it "does not update longest_streak when below previous best" do
        StreakUpdater.call(user)
        expect(user.reload.longest_streak).to eq(5)
      end
    end

    context "breaks personal best" do
      before { user.update_columns(current_streak: 5, longest_streak: 5, last_studied_on: Date.current - 1) }

      it "updates longest_streak" do
        StreakUpdater.call(user)
        expect(user.reload.longest_streak).to eq(6)
      end
    end

    context "already studied today" do
      before { user.update_columns(current_streak: 3, longest_streak: 3, last_studied_on: Date.current) }

      it "is idempotent — does not change streak" do
        StreakUpdater.call(user)
        expect(user.reload.current_streak).to eq(3)
      end
    end

    context "gap of 2+ days" do
      before { user.update_columns(current_streak: 10, longest_streak: 10, last_studied_on: Date.current - 3) }

      it "resets current_streak to 1" do
        StreakUpdater.call(user)
        expect(user.reload.current_streak).to eq(1)
      end

      it "does not reduce longest_streak" do
        StreakUpdater.call(user)
        expect(user.reload.longest_streak).to eq(10)
      end
    end
  end
end
