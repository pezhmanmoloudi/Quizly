require "rails_helper"

RSpec.describe "Flashcards#create", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  let(:valid_params) do
    { flashcard: { front_content: "Term", back_content: "Definition",
                   front_language: "en", back_language: "es" } }
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

      it "persists front_language and back_language" do
        post deck_flashcards_path(deck), params: valid_params
        card = Flashcard.last
        expect(card.front_language).to eq("en")
        expect(card.back_language).to eq("es")
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

    context "when authenticated as another user on a people_with_password deck (not unlocked)" do
      let(:owner)   { create(:user) }
      let(:pw_deck) { create(:deck, :editable_by_password, user: owner) }
      let(:other)   { create(:user) }
      before do
        pw_deck
        sign_in(other)
      end

      it "redirects to the unlock page" do
        post deck_flashcards_path(pw_deck), params: valid_params
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "does not create a flashcard" do
        expect {
          post deck_flashcards_path(pw_deck), params: valid_params
        }.not_to change(Flashcard, :count)
      end
    end

    context "when authenticated as a password user (content domain)" do
      let(:owner)     { create(:user) }
      let(:pw_deck)   { create(:deck, :editable_by_password, user: owner) }
      let(:other)     { create(:user) }
      before do
        sign_in(other)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
      end

      it "creates a flashcard" do
        expect {
          post deck_flashcards_path(pw_deck), params: valid_params
        }.to change(Flashcard, :count).by(1)
        expect(response).to redirect_to(deck_path(pw_deck))
      end
    end
  end
end
