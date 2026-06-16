require "rails_helper"

RSpec.describe "Decks#study", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/study" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get study_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "initializes CardProgress records for new flashcards" do
        create(:flashcard, deck: deck)
        expect {
          get study_deck_path(deck)
        }.to change(CardProgress, :count).by(1)
      end

      it "shows the oldest due card first" do
        newer_card = create(:flashcard, deck: deck)
        older_card = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: newer_card, next_review_at: 1.hour.ago)
        create(:card_progress, :due, user: user, flashcard: older_card, next_review_at: 2.days.ago)
        get study_deck_path(deck)
        expect(response.body).to include(older_card.front_content)
      end

      it "renders the image when the due card has one attached" do
        card = create(:flashcard, deck: deck)
        card.image.attach(
          io: Rails.root.join("spec/fixtures/files/test_avatar.png").open,
          filename: "test_avatar.png",
          content_type: "image/png"
        )
        create(:card_progress, :due, user: user, flashcard: card)
        get study_deck_path(deck)
        expect(response.body).to include("study-card__img")
      end

      it "shows 'All caught up' when no cards are due" do
        flashcard = create(:flashcard, deck: deck)
        create(:card_progress, :future, user: user, flashcard: flashcard)
        get study_deck_path(deck)
        expect(response.body).to include("All caught up")
      end

      it "sets session start time on first card" do
        create(:card_progress, :due, user: user, flashcard: create(:flashcard, deck: deck))
        get study_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects for a private deck belonging to another user" do
        other_deck = create(:deck, user: create(:user))
        get study_deck_path(other_deck)
        expect(response).to redirect_to(decks_path)
      end

      it "returns 200 for a non-owner on a public deck (study? = show?)" do
        public_deck = create(:deck, :public, user: create(:user))
        get study_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a password-protected public deck (non-owner, no session)" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        get study_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 for a password-protected deck after unlocking" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get study_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end

      it "renders the stats header with subtitle and streak badge" do
        create(:card_progress, :due, user: user, flashcard: create(:flashcard, deck: deck))
        get study_deck_path(deck)
        expect(response.body).to include("study-island__stats")
        expect(response.body).to include("study-island__subtitle")
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
