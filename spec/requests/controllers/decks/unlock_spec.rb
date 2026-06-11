require "rails_helper"

RSpec.describe "Decks#unlock", type: :request do
  let(:owner) { create(:user) }
  let(:deck)  { create(:deck, :password_protected, user: owner) }

  describe "GET /decks/:id/unlock" do
    context "when not authenticated" do
      it "renders the unlock form for a password_protected deck" do
        get unlock_deck_path(deck)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Password Required")
      end
    end

    context "when session is already authorized" do
      it "redirects to the deck" do
        post authenticate_deck_path(deck), params: { access_password: "secret123" }
        get unlock_deck_path(deck)
        expect(response).to redirect_to(deck_path(deck))
      end
    end

    context "when authenticated as owner" do
      before { sign_in(owner) }

      it "redirects to the deck (owner can always view)" do
        get unlock_deck_path(deck)
        expect(response).to redirect_to(deck_path(deck))
      end
    end
  end
end
