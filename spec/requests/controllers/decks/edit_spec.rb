require "rails_helper"

RSpec.describe "Decks#edit", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/edit" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get edit_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "renders the edit form pre-filled with deck data" do
        get edit_deck_path(deck)
        expect(response.body).to include(deck.name)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "returns 404" do
        get edit_deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get edit_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
