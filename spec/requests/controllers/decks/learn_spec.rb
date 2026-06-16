require "rails_helper"

RSpec.describe "Decks#learn", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/learn" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "creates a LearnSession on first visit" do
        create(:flashcard, deck: deck)
        expect { get learn_deck_path(deck) }.to change(LearnSession, :count).by(1)
      end

      it "creates LearnSessionItems for all deck cards" do
        3.times { create(:flashcard, deck: deck) }
        get learn_deck_path(deck)
        session_id = LearnSession.last.id
        expect(LearnSessionItem.where(learn_session_id: session_id).count).to eq 3
      end

      it "reuses the active learn session on revisit" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect { get learn_deck_path(deck) }.not_to change(LearnSession, :count)
      end

      it "shows empty state when deck has no cards" do
        get learn_deck_path(deck)
        expect(response.body).to include("No cards yet")
      end

      it "redirects for another user's private deck" do
        other = create(:deck, user: create(:user))
        get learn_deck_path(other)
        expect(response).to redirect_to(decks_path)
      end

      it "returns 200 for a non-owner on a public deck" do
        public_deck = create(:deck, :public, user: create(:user))
        get learn_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a password-protected public deck (non-owner, no session)" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        get learn_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 for a password-protected deck after unlocking" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get learn_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end

      it "renders the stats header with timer and mastered badges" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect(response.body).to include("study-island__stats")
        expect(response.body).to include("learn_counter")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get learn_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
