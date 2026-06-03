require "rails_helper"

RSpec.describe "Decks#show", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user, name: "Spanish Vocab", language_code: "es") }

  describe "GET /decks/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "displays the deck name" do
        get deck_path(deck)
        expect(response.body).to include("Spanish Vocab")
      end

      it "displays the language code" do
        get deck_path(deck)
        expect(response.body).to include("ES")
      end

      it "shows empty state when deck has no flashcards" do
        get deck_path(deck)
        expect(response.body).to include("No flashcards yet")
      end

      it "shows flashcards when they exist" do
        create(:flashcard, deck: deck, front_content: "Hola", back_content: "Hello")
        get deck_path(deck)
        expect(response.body).to include("Hola")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "returns 404 for a private deck" do
        get deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 200 for a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
