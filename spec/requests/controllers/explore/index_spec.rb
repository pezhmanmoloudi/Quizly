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
        create(:deck, user: other_user, visibility: "public", name: "Public Deck A")
        get explore_path
        expect(response.body).to include("Public Deck A")
      end

      it "does not list private decks" do
        create(:deck, user: other_user, visibility: "private", name: "Secret Deck")
        get explore_path
        expect(response.body).not_to include("Secret Deck")
      end

      it "lists public decks from other users" do
        create(:deck, :public, user: other_user, name: "Spanish Deck")
        get explore_path
        expect(response.body).to include("Spanish Deck")
      end

      it "does not show Fork button for any deck" do
        create(:deck, :public, user: other_user, name: "Public Deck")
        get explore_path
        expect(response.body).not_to include(I18n.t("explore.fork"))
      end

      it "filters decks by search query" do
        create(:deck, user: other_user, visibility: "public", name: "Spanish Basics")
        create(:deck, user: other_user, visibility: "public", name: "French Vocab")
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

      context "owner badge indicator" do
        it "shows the owner badge for the user's own public deck" do
          create(:deck, user: user, visibility: "public", name: "My Own Deck")
          get explore_path
          expect(response.body).to include("deck-tile__owner-badge")
        end

        it "shows 'by You' author text for own deck" do
          create(:deck, user: user, visibility: "public", name: "My Own Deck")
          get explore_path
          expect(response.body).to include(I18n.t("explore.by_you"))
        end

        it "does not show the owner badge for another user's deck" do
          create(:deck, user: other_user, visibility: "public", name: "Their Deck")
          get explore_path
          expect(response.body).not_to include("deck-tile__owner-badge")
        end

        it "does not show 'by You' for another user's deck" do
          create(:deck, user: other_user, visibility: "public", name: "Their Deck")
          get explore_path
          expect(response.body).not_to include(I18n.t("explore.by_you"))
        end
      end

      context "saved deck indicator" do
        let(:deck) { create(:deck, user: other_user, visibility: "public", name: "French Vocab") }

        it "shows saved badge for a deck already in the user's library" do
          create(:library_item, user: user, deck: deck)
          get explore_path
          expect(response.body).to include("deck-tile__saved-badge")
        end

        it "does not show saved badge for a deck not in the user's library" do
          deck
          get explore_path
          expect(response.body).not_to include("deck-tile__saved-badge")
        end

        it "does not show saved badge for the user's own public decks" do
          create(:deck, user: user, visibility: "public", name: "My Own Deck")
          get explore_path
          expect(response.body).not_to include("deck-tile__saved-badge")
        end
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
        expect(response.body).to include("Discover and save public decks")
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
        create(:deck, user: create(:user), visibility: "public", name: "Guest Visible Deck")
        get explore_path
        expect(response.body).to include("Guest Visible Deck")
      end

      it "does not show Fork button" do
        create(:deck, user: create(:user), visibility: "public", name: "Some Deck")
        get explore_path
        expect(response.body).not_to include(I18n.t("explore.fork"))
      end

      it "does not show owner badge for any tile" do
        create(:deck, user: create(:user), visibility: "public", name: "Some Deck")
        get explore_path
        expect(response.body).not_to include("deck-tile__owner-badge")
      end
    end
  end
end
