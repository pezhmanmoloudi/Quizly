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

      it "renders the cards island container" do
        get deck_path(deck)
        expect(response.body).to include("cards-island")
      end

      it "renders the items-per-page selector" do
        get deck_path(deck)
        expect(response.body).to include("items-per-page-select")
      end

      it "defaults to 10 items per page" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck)
        expect(response.body).to include("cards-grid")
      end

      it "respects a valid items param" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck), params: { items: 5 }
        expect(response).to have_http_status(:ok)
      end

      it "ignores an invalid items param and defaults to 10" do
        get deck_path(deck), params: { items: 999 }
        expect(response).to have_http_status(:ok)
      end

      it "shows pagination when cards exceed the page size" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck), params: { items: 5 }
        expect(response.body).to include("pagination__btn")
      end

      it "renders a Delete Deck button for the owner" do
        get deck_path(deck)
        expect(response.body).to include("Delete Deck")
        expect(response.body).to include("inline-confirm")
      end

      it "renders an Edit Deck button for the owner" do
        get deck_path(deck)
        expect(response.body).to include("Edit Deck")
        expect(response.body).to include(edit_deck_path(deck))
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

      it "does not render Delete Deck button for a non-owner viewing a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response.body).not_to include("Delete Deck")
      end
    end

    context "when not authenticated" do
      it "returns 404 for a private deck" do
        get deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 200 for a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "does not show Fork button on a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response.body).not_to include("Fork")
      end
    end
  end
end
