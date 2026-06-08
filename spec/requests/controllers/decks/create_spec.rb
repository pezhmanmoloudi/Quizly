require "rails_helper"

RSpec.describe "Decks#create", type: :request do
  let(:user) { create(:user) }

  describe "POST /decks" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a deck and redirects to the deck show page" do
        expect {
          post decks_path, params: { deck: { name: "Spanish Vocab", description: "Basic words", language_code: "es" } }
        }.to change(Deck, :count).by(1)
        expect(response).to redirect_to(deck_path(Deck.last))
      end

      it "creates a deck and redirects to study mode when save_and_study is submitted" do
        expect {
          post decks_path, params: {
            deck: { name: "Spanish Vocab" },
            save_and_study: "Save & Study"
          }
        }.to change(Deck, :count).by(1)
        expect(response).to redirect_to(flashcard_deck_path(Deck.last))
      end

      it "assigns the deck to the current user" do
        post decks_path, params: { deck: { name: "My Deck" } }
        expect(Deck.last.user).to eq(user)
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
