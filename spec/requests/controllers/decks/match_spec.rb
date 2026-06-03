require "rails_helper"

RSpec.describe "Decks#match", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/match" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get match_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "shows up to 8 cards" do
        10.times { |i| create(:flashcard, deck: deck, front_content: "Term #{i}") }
        get match_deck_path(deck)
        expect(response.body).to include("match-tile")
      end

      it "shows empty state when deck has no cards" do
        get match_deck_path(deck)
        expect(response.body).to include("No cards yet")
      end
    end

    context "when authenticated and deck is public" do
      let(:other_user) { create(:user) }
      let(:public_deck) { create(:deck, user: user, visibility: "public") }

      before { sign_in(other_user) }

      it "returns 200 for a public deck owned by another user" do
        get match_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get match_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
