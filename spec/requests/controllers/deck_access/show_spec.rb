require "rails_helper"

RSpec.describe "DeckAccess#show", type: :request do
  let(:owner) { create(:user) }

  describe "GET /decks/:id/unlock" do
    let(:deck) { create(:deck, :password_protected, user: owner) }

    context "when not authenticated" do
      it "renders the unlock form" do
        get unlock_deck_path(deck)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("decks.unlock.title"))
      end
    end

    context "when authenticated as owner" do
      before { sign_in(owner) }

      it "redirects to the deck (owner is always allowed)" do
        get unlock_deck_path(deck)
        expect(response).to redirect_to(deck_path(deck))
      end
    end
  end

  describe "GET /decks/:id/unlock (authorization)" do
    let(:private_deck) { create(:deck, :private, user: owner) }

    context "when another user tries to reach the unlock page of a private deck" do
      before { sign_in(create(:user)) }

      it "redirects away (denied state raises NotAuthorizedError)" do
        get unlock_deck_path(private_deck)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when a guest tries to reach the unlock page of a private deck" do
      it "redirects away (denied state raises NotAuthorizedError)" do
        get unlock_deck_path(private_deck)
        expect(response).to redirect_to(explore_path)
      end
    end
  end
end
