require "rails_helper"

RSpec.describe "Flashcards#update", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck, front_language: "en", back_language: "es") }

  describe "PATCH /flashcards/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "updates front_language and back_language and redirects to deck" do
        patch flashcard_path(flashcard),
              params: { flashcard: { front_content: "Term", back_content: "Definition",
                                     front_language: "fr", back_language: "de" } }
        expect(response).to redirect_to(deck_path(deck))
        flashcard.reload
        expect(flashcard.front_language).to eq("fr")
        expect(flashcard.back_language).to eq("de")
      end

      it "re-renders edit with 422 on invalid params" do
        patch flashcard_path(flashcard),
              params: { flashcard: { front_content: "", back_content: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch flashcard_path(flashcard),
              params: { flashcard: { front_content: "x", back_content: "y" } }
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects away" do
        patch flashcard_path(flashcard),
              params: { flashcard: { front_content: "x", back_content: "y" } }
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when authenticated as a password user (content domain)" do
      let(:owner)   { create(:user) }
      let(:pw_deck) { create(:deck, :editable_by_password, user: owner) }
      let(:pw_card) { create(:flashcard, deck: pw_deck) }
      let(:other)   { create(:user) }
      before do
        sign_in(other)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
      end

      it "updates the flashcard and redirects" do
        patch flashcard_path(pw_card),
              params: { flashcard: { front_content: "Updated", back_content: "Content" } }
        expect(response).to redirect_to(deck_path(pw_deck))
        expect(pw_card.reload.front_content).to eq("Updated")
      end
    end
  end
end
