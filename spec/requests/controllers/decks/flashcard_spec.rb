require "rails_helper"

RSpec.describe "Decks#flashcard", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/flashcard" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get flashcard_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "embeds card progress JSON in study mode" do
        card = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: card)
        get flashcard_deck_path(deck, mode: "study")
        expect(response.body).to include("data-flashcard-browse-progress-value")
        expect(response.body).to include("data-flashcard-browse-mode-value=\"study\"")
      end

      it "does not embed progress JSON in browse mode" do
        get flashcard_deck_path(deck)
        expect(response.body).to include("data-flashcard-browse-mode-value=\"browse\"")
      end

      it "shows all cards" do
        create(:flashcard, deck: deck, front_content: "Front A")
        create(:flashcard, deck: deck, front_content: "Front B")
        get flashcard_deck_path(deck)
        expect(response.body).to include("Front A", "Front B")
      end

      it "renders the image when a card has one attached" do
        card = create(:flashcard, deck: deck)
        card.image.attach(
          io: Rails.root.join("spec/fixtures/files/test_avatar.png").open,
          filename: "test_avatar.png",
          content_type: "image/png"
        )
        get flashcard_deck_path(deck)
        expect(response.body).to include("flashcard-card__img")
      end

      it "shows empty state when deck has no cards" do
        get flashcard_deck_path(deck)
        expect(response.body).to include("No cards yet")
      end
    end

    context "when authenticated and deck is public" do
      let(:other_user) { create(:user) }
      let(:public_deck) { create(:deck, user: user, visibility: "public") }

      before { sign_in(other_user) }

      it "returns 200 for a public deck owned by another user" do
        get flashcard_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated and deck is private and owned by another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get flashcard_deck_path(deck)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to explore for a private deck" do
        get flashcard_deck_path(deck)
        expect(response).to redirect_to(explore_path)
      end

      it "returns 200 for a public deck" do
        public_deck = create(:deck, :public, user: user)
        create(:flashcard, deck: public_deck, front_content: "Public Front")
        get flashcard_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a public password-protected deck (guest, no session)" do
        pw_deck = create(:deck, :password_protected, user: user)
        get flashcard_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 for a public password-protected deck after unlocking" do
        pw_deck = create(:deck, :password_protected, user: user)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get flashcard_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "password-protected deck — owner bypass" do
      before { sign_in(user) }

      it "returns 200 for the owner without needing to unlock" do
        pw_deck = create(:deck, :password_protected, user: user)
        get flashcard_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "password-protected deck — authenticated non-owner" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects to unlock when not unlocked" do
        pw_deck = create(:deck, :password_protected, user: user)
        get flashcard_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 after unlocking" do
        pw_deck = create(:deck, :password_protected, user: user)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get flashcard_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
