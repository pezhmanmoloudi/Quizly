require "rails_helper"

RSpec.describe "Decks#fork", type: :request do
  let(:owner)         { create(:user) }
  let(:forker)        { create(:user) }
  let(:everyone_deck) { create(:deck, user: owner, visibility: "everyone", name: "French Basics") }
  let(:private_deck)  { create(:deck, user: owner, visibility: "private") }
  let(:unlisted_deck) { create(:deck, :unlisted, user: owner, name: "Unlisted Deck") }

  describe "POST /decks/:id/fork" do
    context "when authenticated as another user" do
      before { sign_in(forker) }

      it "creates a copy of an everyone deck" do
        expect {
          post fork_deck_path(everyone_deck)
        }.to change { forker.decks.count }.by(1)
      end

      it "copies all flashcards into the new deck" do
        create(:flashcard, deck: everyone_deck, front_content: "Bonjour", back_content: "Hello")
        post fork_deck_path(everyone_deck)
        copy = forker.decks.last
        expect(copy.flashcards.count).to eq(everyone_deck.flashcards.count)
        expect(copy.flashcards.first.front_content).to eq("Bonjour")
      end

      it "sets forked_from on the copy" do
        post fork_deck_path(everyone_deck)
        copy = forker.decks.last
        expect(copy.forked_from).to eq(everyone_deck)
      end

      it "increments forks_count on the source deck" do
        expect {
          post fork_deck_path(everyone_deck)
        }.to change { everyone_deck.reload.forks_count }.by(1)
      end

      it "sets the copy as private" do
        post fork_deck_path(everyone_deck)
        expect(forker.decks.last.visibility).to eq("private")
      end

      it "redirects to decks_path with notice" do
        post fork_deck_path(everyone_deck)
        expect(response).to redirect_to(decks_path)
        follow_redirect!
        expect(response.body).to include("Deck added to your library")
      end

      it "returns 404 for a private deck" do
        post fork_deck_path(private_deck)
        expect(response).to have_http_status(:not_found)
      end

      it "redirects to unlock when trying to fork a password_protected deck without session auth" do
        pw_deck = create(:deck, :password_protected, user: owner)
        post fork_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      context "with unlisted deck" do
        before { get shared_deck_path(unlisted_deck.share_token) }

        it "creates a copy of an unlisted deck after visiting the share link" do
          expect {
            post fork_deck_path(unlisted_deck)
          }.to change { forker.decks.count }.by(1)
        end

        it "sets the unlisted fork as private" do
          post fork_deck_path(unlisted_deck)
          expect(forker.decks.last.visibility).to eq("private")
        end

        it "sets forked_from on the unlisted copy" do
          post fork_deck_path(unlisted_deck)
          expect(forker.decks.last.forked_from).to eq(unlisted_deck)
        end
      end

      it "returns 404 for an unlisted deck without share link session" do
        post fork_deck_path(unlisted_deck)
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
        post fork_deck_path(everyone_deck)
        expect(response).to redirect_to(login_path)
      end

      it "returns 404 for an unlisted deck (no share session while unauthenticated)" do
        get shared_deck_path(unlisted_deck.share_token)
        post fork_deck_path(unlisted_deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
