require "rails_helper"

RSpec.describe "Study session summary", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  before { sign_in(user) }

  describe "session progress tracking" do
    it "shows progress bar when cards are due" do
      card = create(:flashcard, deck: deck)
      create(:card_progress, :due, user: user, flashcard: card)
      get study_deck_path(deck)
      expect(response.body).to include("study-progress")
    end

    it "does not show progress bar on all-caught-up screen" do
      card = create(:flashcard, deck: deck)
      create(:card_progress, :future, user: user, flashcard: card)
      get study_deck_path(deck)
      expect(response.body).not_to include("study-progress__bar")
    end
  end

  describe "session summary after completing all cards" do
    it "shows session summary after reviewing the last due card" do
      card = create(:flashcard, deck: deck)
      progress = create(:card_progress, :due, user: user, flashcard: card)
      post card_reviews_path, params: { card_progress_id: progress.id, rating: "easy" }
      follow_redirect!
      expect(response.body).to include("Session complete")
    end
  end
end
