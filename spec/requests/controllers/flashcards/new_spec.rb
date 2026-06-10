require "rails_helper"

RSpec.describe "Flashcards#new", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:deck_id/flashcards/new" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get new_deck_flashcard_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "renders the custom language selector for front and back language" do
        get new_deck_flashcard_path(deck)
        expect(response.body).to include('data-controller="language"')
        expect(response.body.scan('data-controller="language"').size).to be >= 2
      end

      it "uses hidden inputs named for the deck flashcard attributes" do
        get new_deck_flashcard_path(deck)
        expect(response.body).to include("front_language")
        expect(response.body).to include("back_language")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_deck_flashcard_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "returns 404" do
        get new_deck_flashcard_path(deck)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
