require "rails_helper"

RSpec.describe "Decks", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/study" do
    context "when authenticated" do
      before { sign_in(user) }

      it "initializes CardProgress records for new flashcards" do
        flashcard = create(:flashcard, deck: deck)
        expect {
          get study_deck_path(deck)
        }.to change(CardProgress, :count).by(1)
      end

      it "returns 200 OK" do
        get study_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "shows the oldest due card first" do
        newer_card = create(:flashcard, deck: deck)
        older_card = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: newer_card,
               next_review_at: 1.hour.ago)
        create(:card_progress, :due, user: user, flashcard: older_card,
               next_review_at: 2.days.ago)

        get study_deck_path(deck)
        expect(response.body).to include(older_card.front_content)
      end

      it "shows 'All caught up' when no cards are due" do
        flashcard = create(:flashcard, deck: deck)
        create(:card_progress, :future, user: user, flashcard: flashcard)

        get study_deck_path(deck)
        expect(response.body).to include("All caught up")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get study_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
