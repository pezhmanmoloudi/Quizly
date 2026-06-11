require "rails_helper"

RSpec.describe "Explore#index", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /explore" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get explore_path
        expect(response).to have_http_status(:ok)
      end

      it "lists public decks from other users" do
        create(:deck, user: other_user, visibility: "everyone", name: "Public Deck A")
        get explore_path
        expect(response.body).to include("Public Deck A")
      end

      it "does not list private decks" do
        create(:deck, user: other_user, visibility: "private", name: "Secret Deck")
        get explore_path
        expect(response.body).not_to include("Secret Deck")
      end

      it "filters decks by search query" do
        create(:deck, user: other_user, visibility: "everyone", name: "Spanish Basics")
        create(:deck, user: other_user, visibility: "everyone", name: "French Vocab")
        get explore_path, params: { q: "Spanish" }
        expect(response.body).to include("Spanish Basics")
        expect(response.body).not_to include("French Vocab")
      end

      it "shows empty state when no public decks exist" do
        get explore_path
        expect(response.body).to include("No public decks yet")
      end

      it "shows empty search result message when query matches nothing" do
        get explore_path, params: { q: "nonexistent deck xyz" }
        expect(response.body).to include("No decks found for")
      end
    end

    context "locale persistence on unauthenticated-accessible page" do
      before { sign_in(user) }

      it "renders in the user's saved locale" do
        user.update!(locale: "es")
        get explore_path
        expect(response.body).to include("Explorar")
      end

      it "renders in English for users with default locale" do
        get explore_path
        expect(response.body).to include("Discover and fork public decks")
      end

      it "keeps the topbar brand LTR in an RTL locale" do
        user.update!(locale: "ar")
        get explore_path
        expect(response.body).to include('class="topbar__brand" dir="ltr"')
      end
    end

    context "when not authenticated" do
      it "returns 200" do
        get explore_path
        expect(response).to have_http_status(:ok)
      end

      it "lists public decks without logging in" do
        create(:deck, user: create(:user), visibility: "everyone", name: "Guest Visible Deck")
        get explore_path
        expect(response.body).to include("Guest Visible Deck")
      end

      it "does not show Fork button" do
        create(:deck, user: create(:user), visibility: "everyone", name: "Some Deck")
        get explore_path
        expect(response.body).not_to include("Fork")
      end
    end
  end
end
