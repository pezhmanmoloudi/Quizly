require "rails_helper"

RSpec.describe "Decks#destroy", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "DELETE /decks/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "destroys the deck and redirects to index" do
        deck_to_delete = create(:deck, user: user)
        expect {
          delete deck_path(deck_to_delete)
        }.to change(Deck, :count).by(-1)
        expect(response).to redirect_to(decks_path)
      end

      it "destroys associated flashcards" do
        flashcard = create(:flashcard, deck: deck)
        expect {
          delete deck_path(deck)
        }.to change(Flashcard, :count).by(-1)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "returns 404" do
        delete deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end

      it "does not destroy the deck" do
        deck
        expect {
          delete deck_path(deck)
        }.not_to change(Deck, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
