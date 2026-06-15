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

      it "renders existing flashcard content in the card list" do
        card = create(:flashcard, deck: deck, front_content: "bonjour", back_content: "hello")
        get edit_deck_path(deck)
        expect(response.body).to include("bonjour")
        expect(response.body).to include("hello")
      end

      it "renders the card autosave controller on each card row" do
        create(:flashcard, deck: deck, front_content: "hola", back_content: "hi")
        get edit_deck_path(deck)
        expect(response.body).to include("card-autosave")
      end

      it "includes the Add Card button" do
        get edit_deck_path(deck)
        expect(response.body).to include("deck-editor")
      end
    end

    context "when authenticated as another user" do
      let(:other) { create(:user) }
      before { sign_in(other) }

      it "redirects for an only_me deck" do
        get edit_deck_path(deck)
        expect(response).to redirect_to(decks_path)
      end

      it "redirects for a people_with_password deck without session auth" do
        pw_deck = create(:deck, :editable_by_password, user: user)
        get edit_deck_path(pw_deck)
        expect(response).to redirect_to(decks_path)
      end

      it "redirects for a people_with_password deck even with session auth (admin domain is owner-only)" do
        pw_deck = create(:deck, :editable_by_password, user: user)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get edit_deck_path(pw_deck)
        expect(response).to redirect_to(decks_path)
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
