require "rails_helper"

RSpec.describe "Decks#unlock", type: :request do
  let(:owner) { create(:user) }

  describe "GET /decks/:id/unlock" do
    let(:deck) { create(:deck, :editable_by_password, user: owner) }

    context "when not authenticated" do
      it "renders the unlock form" do
        get unlock_deck_path(deck)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("decks.unlock.title"))
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

  describe "POST /decks/:id/unlock" do
    let(:deck) { create(:deck, :editable_by_password, user: owner) }

    context "with the correct password" do
      it "sets the session unlock flag and redirects to the deck" do
        post unlock_deck_path(deck), params: { password: "secret123" }
        expect(session["deck_#{deck.id}_unlocked"]).to be true
        expect(response).to redirect_to(deck_path(deck))
      end
    end

    context "with an incorrect password" do
      it "re-renders the unlock form with an error" do
        post unlock_deck_path(deck), params: { password: "wrongpass" }
        expect(session["deck_#{deck.id}_unlocked"]).not_to be true
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a blank password" do
      it "re-renders the unlock form with an error" do
        post unlock_deck_path(deck), params: { password: "" }
        expect(session["deck_#{deck.id}_unlocked"]).not_to be true
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
