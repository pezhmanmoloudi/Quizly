require "rails_helper"

RSpec.describe "Card Reviews", type: :request do
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

      it "returns 404 when accessing another user's card_progress" do
        other_user      = create(:user)
        other_flashcard = create(:flashcard, deck: create(:deck, user: other_user))
        other_cp        = create(:card_progress, user: other_user, flashcard: other_flashcard)

        post card_reviews_path, params: {
          card_progress_id: other_cp.id,
          rating: "good"
        }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post card_reviews_path, params: {
          card_progress_id: card_progress.id,
          rating: "good"
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
