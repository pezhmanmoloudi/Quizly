require "rails_helper"

RSpec.describe "Dashboard#index", type: :request do
  let(:user) { create(:user) }

  describe "GET /dashboard" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it "displays the user's display name in the hero" do
        get dashboard_path
        expect(response.body).to include(user.display_name)
      end

      it "shows total deck count" do
        create_list(:deck, 3, user: user)
        get dashboard_path
        expect(response.body).to include("3")
      end

      it "shows total card count across all user decks" do
        deck = create(:deck, user: user)
        create_list(:flashcard, 5, deck: deck)
        get dashboard_path
        expect(response.body).to include("5")
      end

      it "shows the My Library section header in the sidebar" do
        get dashboard_path
        expect(response.body).to include("My Library")
      end

      it "shows the global create deck button in the topbar" do
        get dashboard_path
        expect(response.body).to include("topbar__create-btn")
        expect(response.body).to include('aria-label="Create Deck"')
      end

      it "shows Cards Due stat" do
        deck = create(:deck, user: user)
        flashcard = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: flashcard)
        get dashboard_path
        expect(response.body).to include("Cards Due")
      end

      it "shows the user's own decks in the My Decks section" do
        create(:deck, user: user, name: "My Spanish Deck")
        get dashboard_path
        expect(response.body).to include("My Spanish Deck")
      end

      it "does not show decks from other users" do
        create(:deck, user: create(:user), name: "Stranger's Deck", visibility: "public")
        get dashboard_path
        expect(response.body).not_to include("Stranger&#39;s Deck")
      end

    end

    context "when not authenticated" do
      it "redirects to login" do
        get dashboard_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
