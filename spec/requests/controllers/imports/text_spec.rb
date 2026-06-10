require "rails_helper"

RSpec.describe "Imports#text", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  before { sign_in(user) }

  describe "POST /decks/:deck_id/import/text" do
    let(:valid_text) { "Hello\tHola\nGoodbye\tAdiós" }

    it "does NOT create any Flashcard records" do
      expect {
        post text_deck_import_path(deck), params: { text: valid_text }
      }.not_to change(Flashcard, :count)
    end

    it "renders the card editor (200) with parsed rows pre-filled" do
      post text_deck_import_path(deck), params: { text: valid_text }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hello")
      expect(response.body).to include("Hola")
    end

    it "does not store anything in the session" do
      post text_deck_import_path(deck), params: { text: valid_text }
      expect(session[:card_editor_draft_id]).to be_nil
      expect(session[:card_editor_imported]).to be_nil
    end

    it "renders error for blank text" do
      post text_deck_import_path(deck), params: { text: "" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "renders error when no valid pairs found" do
      post text_deck_import_path(deck), params: { text: "no separator here" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for another user's deck" do
      other_deck = create(:deck, user: create(:user))
      post text_deck_import_path(other_deck), params: { text: valid_text }
      expect(response).to have_http_status(:not_found)
    end
  end
end
