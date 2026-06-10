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

      it "returns 404" do
        get flashcard_deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "returns 404 for a private deck" do
        get flashcard_deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 200 for a public deck" do
        public_deck = create(:deck, :public, user: user)
        create(:flashcard, deck: public_deck, front_content: "Public Front")
        get flashcard_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
