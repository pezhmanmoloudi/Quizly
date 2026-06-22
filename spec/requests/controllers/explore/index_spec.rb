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
        create(:deck, :public, user: other_user, name: "Public Deck A")
        get explore_path
        expect(response.body).to include("Public Deck A")
      end

      it "does not list private decks" do
        create(:deck, user: other_user, visibility: "private", name: "Secret Deck")
        get explore_path
        expect(response.body).not_to include("Secret Deck")
      end

      it "does not list unlisted decks" do
        create(:deck, :unlisted, user: other_user, name: "Unlisted Hidden Deck")
        get explore_path
        expect(response.body).not_to include("Unlisted Hidden Deck")
      end

      it "filters decks by search query" do
        create(:deck, :public, user: other_user, name: "Spanish Basics")
        create(:deck, :public, user: other_user, name: "French Vocab")
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

      context "author name" do
        it "shows the deck creator's display name" do
          create(:deck, :public, user: other_user, name: "Their Deck")
          get explore_path
          expect(response.body).to include(other_user.display_name)
        end
      end

      context "public + open decks" do
        it "lists them in explore" do
          deck = create(:deck, visibility: "public", access_mode: "open", user: other_user, name: "Open Public Deck")
          create(:flashcard, deck: deck)
          get explore_path
          expect(response.body).to include("Open Public Deck")
        end

        it "does not show a lock icon" do
          deck = create(:deck, visibility: "public", access_mode: "open", user: other_user, name: "Open Public Deck")
          create(:flashcard, deck: deck)
          get explore_path
          expect(response.body).not_to include("deck-tile__lock-icon")
        end
      end

      context "password-protected public decks" do
        it "lists them (password does not affect discoverability)" do
          create(:deck, :password_protected, user: other_user, name: "Locked Public Deck")
          get explore_path
          expect(response.body).to include("Locked Public Deck")
        end

        it "shows a closed lock icon for password-protected decks" do
          create(:deck, :password_protected, user: other_user, name: "Locked Public Deck")
          get explore_path
          expect(response.body).to include("deck-row__lock-icon--closed")
        end

        it "shows an open lock icon when the deck is owned by the current user" do
          create(:deck, :password_protected, user: user, name: "My Locked Deck")
          get explore_path
          expect(response.body).to include("deck-row__lock-icon--open")
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
        create(:deck, :public, user: create(:user), name: "Guest Visible Deck")
        get explore_path
        expect(response.body).to include("Guest Visible Deck")
      end

      it "does not list unlisted decks" do
        create(:deck, :unlisted, user: create(:user), name: "Unlisted Hidden Guest")
        get explore_path
        expect(response.body).not_to include("Unlisted Hidden Guest")
      end

      it "does not list private decks" do
        create(:deck, :private, user: create(:user), name: "Private Hidden Guest")
        get explore_path
        expect(response.body).not_to include("Private Hidden Guest")
      end

      it "shows the deck creator's display name for unauthenticated visitors" do
        creator = create(:user)
        create(:deck, :public, user: creator, name: "Some Deck")
        get explore_path
        expect(response.body).to include(creator.display_name)
      end

      it "lists password-protected public decks for guests" do
        create(:deck, :password_protected, user: create(:user), name: "Guest Locked Deck")
        get explore_path
        expect(response.body).to include("Guest Locked Deck")
      end

      it "lists public + open decks for guests" do
        deck = create(:deck, visibility: "public", access_mode: "open", user: create(:user), name: "Guest Open Deck")
        create(:flashcard, deck: deck)
        get explore_path
        expect(response.body).to include("Guest Open Deck")
      end
    end
  end
end
