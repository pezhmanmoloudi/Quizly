require "rails_helper"

RSpec.describe "Decks#show", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user, name: "Spanish Vocab", language_code: "es") }

  describe "GET /decks/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "displays the deck name" do
        get deck_path(deck)
        expect(response.body).to include("Spanish Vocab")
      end

      it "displays the language code" do
        get deck_path(deck)
        expect(response.body).to include("ES")
      end

      it "shows card count as zero when deck has no flashcards" do
        get deck_path(deck)
        expect(response.body).to match(/cards-island__count[^>]*>0<\/span>/)
      end

      it "shows flashcards when they exist" do
        create(:flashcard, deck: deck, front_content: "Hola", back_content: "Hello")
        get deck_path(deck)
        expect(response.body).to include("Hola")
      end

      it "renders the cards island container" do
        get deck_path(deck)
        expect(response.body).to include("cards-island")
      end

      it "renders the items-per-page selector" do
        get deck_path(deck)
        expect(response.body).to include("items-per-page-select")
      end

      it "defaults to 10 items per page" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck)
        expect(response.body).to include("cards-grid")
      end

      it "respects a valid items param" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck), params: { items: 5 }
        expect(response).to have_http_status(:ok)
      end

      it "ignores an invalid items param and defaults to 10" do
        get deck_path(deck), params: { items: 999 }
        expect(response).to have_http_status(:ok)
      end

      it "shows pagination when cards exceed the page size" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck), params: { items: 5 }
        expect(response.body).to include("pagination__btn")
      end

      it "renders a Delete Deck button for the owner" do
        get deck_path(deck)
        expect(response.body).to include("Delete Deck")
        expect(response.body).to include("delete-deck-modal")
      end

      it "renders an Edit Deck button for the owner" do
        get deck_path(deck)
        expect(response.body).to include("Edit Deck")
        expect(response.body).to include(edit_deck_path(deck))
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "returns 404 for a private deck" do
        get deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 200 for an everyone deck" do
        everyone_deck = create(:deck, :everyone, user: user)
        get deck_path(everyone_deck)
        expect(response).to have_http_status(:ok)
      end

      it "does not render Delete Deck button for a non-owner viewing an everyone deck" do
        everyone_deck = create(:deck, :everyone, user: user)
        get deck_path(everyone_deck)
        expect(response.body).not_to include("Delete Deck")
      end

      it "redirects to unlock for a password_protected deck" do
        pw_deck = create(:deck, :password_protected, user: user)
        get deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 for a password_protected deck when session is authorized" do
        pw_deck = create(:deck, :password_protected, user: user)
        post authenticate_deck_path(pw_deck), params: { access_password: "secret123" }
        get deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end

      it "returns 404 for an unlisted deck without share session" do
        unlisted_deck = create(:deck, :unlisted, user: user)
        get deck_path(unlisted_deck)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 200 for an unlisted deck after visiting the share link" do
        unlisted_deck = create(:deck, :unlisted, user: user)
        get shared_deck_path(unlisted_deck.share_token)
        get deck_path(unlisted_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "returns 404 for a private deck" do
        get deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 200 for an everyone deck" do
        everyone_deck = create(:deck, :everyone, user: user)
        get deck_path(everyone_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a password_protected deck" do
        pw_deck = create(:deck, :password_protected, user: user)
        get deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "does not show Fork button on an everyone deck" do
        everyone_deck = create(:deck, :everyone, user: user)
        get deck_path(everyone_deck)
        expect(response.body).not_to include("Fork")
      end

      it "returns 404 for an unlisted deck without share session" do
        unlisted_deck = create(:deck, :unlisted, user: user)
        get deck_path(unlisted_deck)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "unlisted deck noindex and forked_from" do
      let(:unlisted_deck) { create(:deck, :unlisted, user: user) }

      before { sign_in(user) }

      it "sets X-Robots-Tag: noindex for an unlisted deck" do
        get deck_path(unlisted_deck)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex")
      end

      it "does not set X-Robots-Tag for a public deck" do
        everyone_deck = create(:deck, :everyone, user: user)
        get deck_path(everyone_deck)
        expect(response.headers["X-Robots-Tag"]).to be_nil
      end

      it "shows the forked_from link when source deck is public" do
        source = create(:deck, :everyone, user: create(:user), name: "Source Deck")
        forked = create(:deck, user: user, forked_from: source)
        get deck_path(forked)
        expect(response.body).to include("Source Deck")
        expect(response.body).to include(deck_path(source))
      end

      it "hides the source deck name when source is not public" do
        source = create(:deck, :unlisted, user: create(:user), name: "Secret Source")
        forked = create(:deck, user: user, forked_from: source)
        get deck_path(forked)
        expect(response.body).not_to include("Secret Source")
        expect(response.body).not_to include(deck_path(source))
      end
    end
  end
end
