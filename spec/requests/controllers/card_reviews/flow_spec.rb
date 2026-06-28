require "rails_helper"

RSpec.describe "CardReviews#create — redirect flow and data updates", type: :request do
  let(:user)          { create(:user) }
  let(:deck)          { create(:deck, user: user) }
  let(:flashcard)     { create(:flashcard, deck: deck) }
  let(:card_progress) { create(:card_progress, :due, user: user, flashcard: flashcard) }

  describe "POST /card_reviews" do
    context "when authenticated" do
      before { sign_in(user) }

      it "redirects to the study page after grading" do
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "good"
        }
        expect(response).to redirect_to(study_deck_path(deck))
      end

      it "updates the card's next_review_at" do
        original_next = card_progress.next_review_at
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "good"
        }
        expect(card_progress.reload.next_review_at).to be > original_next
      end

      it "includes session-complete text in the flash when it is the last due card" do
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "easy"
        }
        follow_redirect!
        expect(response.body).to include("Session complete")
      end

      it "redirects without a summary flash when more due cards remain" do
        card2 = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: card2)
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "good"
        }
        expect(response).to redirect_to(study_deck_path(deck))
      end

      it "includes elapsed time in the flash when a study session was started" do
        card_progress
        get study_deck_path(deck)
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "easy"
        }
        follow_redirect!
        expect(response.body).to include("Time spent")
      end

      it "does not include time spent when no study session was started" do
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "easy"
        }
        follow_redirect!
        expect(response.body).to include("Session complete")
        expect(response.body).not_to include("Time spent")
      end

      it "redirects to decks page when accessing another user's card_progress" do
        other_user      = create(:user)
        other_flashcard = create(:flashcard, deck: create(:deck, user: other_user))
        other_cp        = create(:card_progress, user: other_user, flashcard: other_flashcard)

        post card_reviews_path, params: {
          card_progress_id: other_cp.id,
          rating: "good"
        }
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "good"
        }
        expect(response).to redirect_to(login_path)
      end
    end

    context "new_limit session enforcement" do
      before { sign_in(user) }

      it "increments new_cards_reviewed in session when reviewing a new card" do
        extra = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: extra, repetitions: 0)
        cp = create(:card_progress, :due, user: user, flashcard: flashcard, repetitions: 0)
        get study_deck_path(deck, new_limit: 5)
        post card_reviews_path, params: { card_progress_id: cp.id, rating: "good", new_limit: "5" }
        expect(session[:new_cards_reviewed]).to eq(1)
      end

      it "does not increment new_cards_reviewed when reviewing a review card" do
        extra = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: extra, repetitions: 0)
        cp = create(:card_progress, :due, user: user, flashcard: flashcard, repetitions: 3)
        get study_deck_path(deck, new_limit: 5)
        post card_reviews_path, params: { card_progress_id: cp.id, rating: "good", new_limit: "5" }
        expect(session[:new_cards_reviewed]).to eq(0)
      end

      it "ends the session after reviewing new_limit new cards even when more new cards remain" do
        cards = create_list(:flashcard, 3, deck: deck)
        cp1, cp2, _cp3 = cards.map { |c| create(:card_progress, :due, user: user, flashcard: c, repetitions: 0) }

        get study_deck_path(deck, new_limit: 2)
        post card_reviews_path, params: { card_progress_id: cp1.id, rating: "good", new_limit: "2" }
        expect(response).to redirect_to(study_deck_path(deck, new_limit: "2"))

        post card_reviews_path, params: { card_progress_id: cp2.id, rating: "good", new_limit: "2" }
        expect(response).to redirect_to(study_deck_path(deck, new_limit: "2"))
        expect(flash[:study_summary]).to be_present
      end

      it "preserves new_cards_reviewed in session on completion so the final frame redirect shows remaining=0" do
        cp = create(:card_progress, :due, user: user, flashcard: flashcard, repetitions: 0)
        get study_deck_path(deck, new_limit: 1)
        post card_reviews_path, params: { card_progress_id: cp.id, rating: "good", new_limit: "1" }
        expect(session[:new_cards_reviewed]).to eq(1)
      end
    end
  end
end
