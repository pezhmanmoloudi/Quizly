require "rails_helper"

RSpec.describe "Decks#destroy", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "DELETE /decks/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "destroys the deck" do
        deck_to_delete = create(:deck, user: user)
        expect {
          delete deck_path(deck_to_delete)
        }.to change(Deck, :count).by(-1)
      end

      it "redirects to index page 1 by default" do
        delete deck_path(deck)
        expect(response).to redirect_to(decks_path(page: 1))
      end

      it "redirects to the requested from_page when other decks fill that page" do
        # Need 13 remaining after deletion so page 2 is valid — create 14 total
        create_list(:deck, DecksController::DECK_INDEX_PER_PAGE + 1, user: user)
        deck_to_delete = create(:deck, user: user)
        delete deck_path(deck_to_delete), params: { from_page: 2 }
        expect(response).to redirect_to(decks_path(page: 2))
      end

      it "clamps redirect to the last valid page when from_page exceeds remaining pages" do
        # Only one deck exists — deleting it means last_page = 1
        delete deck_path(deck), params: { from_page: 5 }
        expect(response).to redirect_to(decks_path(page: 1))
      end

      it "destroys associated flashcards" do
        create(:flashcard, deck: deck)
        expect {
          delete deck_path(deck)
        }.to change(Flashcard, :count).by(-1)
      end

      it "redirects via turbo_stream format too" do
        delete deck_path(deck), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to be_redirect
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects away" do
        delete deck_path(deck)
        expect(response).to redirect_to(decks_path)
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
