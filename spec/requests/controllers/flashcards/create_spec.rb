require "rails_helper"

RSpec.describe "Flashcards#create", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  let(:valid_params) do
    { flashcard: { front_content: "Term", back_content: "Definition" } }
  end

  describe "POST /decks/:deck_id/flashcards" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "creates a flashcard and redirects to the deck" do
        expect {
          post deck_flashcards_path(deck), params: valid_params
        }.to change(Flashcard, :count).by(1)
        expect(response).to redirect_to(deck_path(deck))
      end

      it "inherits front_language and back_language from the deck" do
        deck.update_columns(term_language: "en", definition_language: "fa")
        post deck_flashcards_path(deck), params: valid_params
        card = deck.flashcards.last
        expect(card.front_language).to eq("en")
        expect(card.back_language).to eq("fa")
      end

      it "redirects to editor with alert on invalid params" do
        post deck_flashcards_path(deck),
             params: { flashcard: { front_content: "", back_content: "" } }
        expect(response).to redirect_to(edit_deck_path(deck))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post deck_flashcards_path(deck), params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects away" do
        post deck_flashcards_path(deck), params: valid_params
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when authenticated as another user on a password-protected deck" do
      let(:owner)    { create(:user) }
      let!(:pw_deck) { create(:deck, :password_protected, user: owner) }
      let(:other)    { create(:user) }
      before { sign_in(other) }

      it "redirects away without creating a flashcard (edit is owner-only)" do
        expect {
          post deck_flashcards_path(pw_deck), params: valid_params
        }.not_to change(Flashcard, :count)
        expect(response).to redirect_to(decks_path)
      end
    end
  end
end
