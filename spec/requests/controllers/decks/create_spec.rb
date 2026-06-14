require "rails_helper"

RSpec.describe "Decks#create", type: :request do
  let(:user) { create(:user) }

  describe "POST /decks" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a deck and redirects to the card editor" do
        expect {
          post decks_path, params: { deck: { name: "Spanish Vocab", description: "Basic words",
                                             language_code: "es", visibility: "private" } }
        }.to change(Deck, :count).by(1)
        expect(response).to redirect_to(cards_deck_path(Deck.last))
      end

      it "assigns the deck to the current user" do
        post decks_path, params: { deck: { name: "My Deck", visibility: "private" } }
        expect(Deck.last.user).to eq(user)
      end

      it "creates an unlisted deck that is excluded from explore" do
        post decks_path, params: { deck: { name: "My Secret Deck", visibility: "unlisted" } }
        expect(Deck.discoverable).not_to include(Deck.last)
      end

      it "does not create a deck with a blank name" do
        expect {
          post decks_path, params: { deck: { name: "" } }
        }.not_to change(Deck, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a deck with a name exceeding 100 characters" do
        expect {
          post decks_path, params: { deck: { name: "A" * 101 } }
        }.not_to change(Deck, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post decks_path, params: { deck: { name: "Test" } }
        expect(response).to redirect_to(login_path)
      end

      it "does not create a deck" do
        expect {
          post decks_path, params: { deck: { name: "Test" } }
        }.not_to change(Deck, :count)
      end
    end
  end
end
