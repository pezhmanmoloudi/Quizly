require "rails_helper"

RSpec.describe "Decks#match", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/match" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get match_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "shows match tiles for all deck cards" do
        10.times { |i| create(:flashcard, deck: deck, front_content: "Term #{i}") }
        get match_deck_path(deck)
        expect(response.body).to include("match-tile")
      end

      it "shows empty state when deck has no cards" do
        get match_deck_path(deck)
        expect(response.body).to include("No cards yet")
      end

      it "renders inside the match-island container" do
        get match_deck_path(deck)
        expect(response.body).to include("match-island")
      end
    end

    context "when authenticated and deck is public" do
      let(:other_user) { create(:user) }
      let(:public_deck) { create(:deck, user: user, visibility: "public") }

      before { sign_in(other_user) }

      it "returns 200 for a public deck owned by another user" do
        get match_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to explore for a private deck" do
        get match_deck_path(deck)
        expect(response).to redirect_to(explore_path)
      end

      it "returns 200 for a public deck" do
        public_deck = create(:deck, :public, user: user)
        get match_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "shows Sign in CTA banner on a public deck with cards" do
        public_deck = create(:deck, :public, user: user)
        create(:flashcard, deck: public_deck)
        get match_deck_path(public_deck)
        expect(response.body).to include("Sign in")
      end

      it "redirects to unlock for a public password-protected deck (guest, no session)" do
        pw_deck = create(:deck, :password_protected, user: user)
        get match_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 for a public password-protected deck after unlocking" do
        pw_deck = create(:deck, :password_protected, user: user)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get match_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "password-protected deck — owner bypass" do
      before { sign_in(user) }

      it "returns 200 for the owner without needing to unlock" do
        pw_deck = create(:deck, :password_protected, user: user)
        get match_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "password-protected deck — authenticated non-owner" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects to unlock when not unlocked" do
        pw_deck = create(:deck, :password_protected, user: user)
        get match_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 after unlocking" do
        pw_deck = create(:deck, :password_protected, user: user)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get match_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
