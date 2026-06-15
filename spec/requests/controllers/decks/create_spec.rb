require "rails_helper"

RSpec.describe "Decks#create", type: :request do
  let(:user) { create(:user) }

  describe "POST /decks" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a deck with the default name and private visibility" do
        expect { post decks_path }.to change(Deck, :count).by(1)
        deck = Deck.last
        expect(deck.name).to eq(I18n.t("decks.default_name"))
        expect(deck.visibility).to eq("private")
      end

      it "assigns the deck to the current user" do
        post decks_path
        expect(Deck.last.user).to eq(user)
      end

      it "redirects immediately to the edit page" do
        post decks_path
        expect(response).to redirect_to(edit_deck_path(Deck.last))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post decks_path
        expect(response).to redirect_to(login_path)
      end

      it "does not create a deck" do
        expect { post decks_path }.not_to change(Deck, :count)
      end
    end
  end
end
