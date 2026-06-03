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

      it "shows all decks belonging to the current user" do
        create_list(:deck, 6, user: user)
        get dashboard_path
        tile_count = response.body.scan("deck-tile__name").count
        expect(tile_count).to eq(6)
      end

      it "shows only decks belonging to the current user" do
        own_deck   = create(:deck, user: user, name: "My Deck")
        other_deck = create(:deck, user: create(:user), name: "Stranger's Deck")
        get dashboard_path
        expect(response.body).to include("My Deck")
        expect(response.body).not_to include("Stranger's Deck")
      end

      it "shows total card count across all user decks" do
        deck = create(:deck, user: user)
        create_list(:flashcard, 5, deck: deck)
        get dashboard_path
        expect(response.body).to include("5")
      end

      it "shows the New Deck link in the sidebar" do
        get dashboard_path
        expect(response.body).to include("New Deck")
      end

      it "shows the Settings link in the sidebar" do
        get dashboard_path
        expect(response.body).to include("Settings")
      end

      it "shows Cards Due stat" do
        deck = create(:deck, user: user)
        flashcard = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: flashcard)
        get dashboard_path
        expect(response.body).to include("Cards Due")
      end

      context "when user has no decks" do
        it "shows the empty state" do
          get dashboard_path
          expect(response.body).to include("Create your first deck")
        end

        it "shows the empty state description" do
          get dashboard_path
          expect(response.body).to include("Start building flashcards")
        end

        it "shows a Create a Deck CTA button" do
          get dashboard_path
          expect(response.body).to include("Create a Deck")
          expect(response.body).to include(new_deck_path)
        end
      end

      context "when user has decks" do
        it "does not show the empty state" do
          create(:deck, user: user)
          get dashboard_path
          expect(response.body).not_to include("Create your first deck")
        end
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
