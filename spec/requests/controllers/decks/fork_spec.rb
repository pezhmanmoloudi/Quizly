require "rails_helper"

RSpec.describe "Decks#fork", type: :request do
  let(:owner) { create(:user) }
  let(:forker) { create(:user) }
  let(:public_deck) { create(:deck, user: owner, visibility: "public", name: "French Basics") }
  let(:private_deck) { create(:deck, user: owner, visibility: "private") }

  describe "POST /decks/:id/fork" do
    context "when authenticated as another user" do
      before { sign_in(forker) }

      it "creates a copy of a public deck" do
        expect {
          post fork_deck_path(public_deck)
        }.to change { forker.decks.count }.by(1)
      end

      it "copies all flashcards into the new deck" do
        create(:flashcard, deck: public_deck, front_content: "Bonjour", back_content: "Hello")
        post fork_deck_path(public_deck)
        copy = forker.decks.last
        expect(copy.flashcards.count).to eq(public_deck.flashcards.count)
        expect(copy.flashcards.first.front_content).to eq("Bonjour")
      end

      it "sets forked_from on the copy" do
        post fork_deck_path(public_deck)
        copy = forker.decks.last
        expect(copy.forked_from).to eq(public_deck)
      end

      it "increments forks_count on the source deck" do
        expect {
          post fork_deck_path(public_deck)
        }.to change { public_deck.reload.forks_count }.by(1)
      end

      it "sets the copy as private" do
        post fork_deck_path(public_deck)
        expect(forker.decks.last.visibility).to eq("private")
      end

      it "redirects to decks_path with notice" do
        post fork_deck_path(public_deck)
        expect(response).to redirect_to(decks_path)
        follow_redirect!
        expect(response.body).to include("Deck added to your library")
      end

      it "returns 404 for a private deck" do
        post fork_deck_path(private_deck)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as the deck owner" do
      before { sign_in(owner) }

      it "redirects to explore when trying to fork own private deck" do
        post fork_deck_path(private_deck)
        expect(response).to redirect_to(explore_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post fork_deck_path(public_deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
