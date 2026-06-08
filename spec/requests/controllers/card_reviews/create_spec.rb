require "rails_helper"

RSpec.describe "CardReviews#create — streak and badge triggering", type: :request do
  let(:user)          { create(:user) }
  let(:deck)          { create(:deck, user: user) }
  let(:flashcard)     { create(:flashcard, deck: deck) }
  let(:card_progress) { create(:card_progress, :due, user: user, flashcard: flashcard) }

  before do
    sign_in(user)
    card_progress  # ensure the due card exists before the GET
    get study_deck_path(deck)  # creates study session and sets study_session_id cookie
  end

  context "when the last due card is reviewed" do
    it "calls StreakUpdater" do
      expect(StreakUpdater).to receive(:call).with(user)
      post card_reviews_path, params: { card_progress_id: card_progress.id, rating: "easy" }
    end

    it "calls BadgeAwarder" do
      expect(BadgeAwarder).to receive(:call).with(user)
      post card_reviews_path, params: { card_progress_id: card_progress.id, rating: "easy" }
    end
  end

  context "when more due cards remain" do
    before do
      card2 = create(:flashcard, deck: deck)
      create(:card_progress, :due, user: user, flashcard: card2)
    end

    it "does not call StreakUpdater" do
      expect(StreakUpdater).not_to receive(:call)
      post card_reviews_path, params: { card_progress_id: card_progress.id, rating: "good" }
    end

    it "does not call BadgeAwarder" do
      expect(BadgeAwarder).not_to receive(:call)
      post card_reviews_path, params: { card_progress_id: card_progress.id, rating: "good" }
    end
  end
end
