require "rails_helper"

RSpec.describe "Imports#text", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  before { sign_in(user) }

  describe "POST /decks/:deck_id/import/text" do
    let(:valid_text) { "Hello\tHola\nGoodbye\tAdiós" }

    it "creates flashcard records directly" do
      expect {
        post text_deck_import_path(deck), params: { text: valid_text, col_sep: "\t", row_sep: "\n" }
      }.to change(Flashcard, :count).by(2)
    end

    it "redirects to the deck after successful import" do
      post text_deck_import_path(deck), params: { text: valid_text }
      expect(response).to redirect_to(deck_path(deck))
    end

    it "does not store anything in the session" do
      post text_deck_import_path(deck), params: { text: valid_text }
      expect(session[:card_editor_draft_id]).to be_nil
      expect(session[:card_editor_imported]).to be_nil
    end

    it "redirects to deck with alert for blank text" do
      post text_deck_import_path(deck), params: { text: "" }
      expect(response).to redirect_to(deck_path(deck))
      follow_redirect!
      expect(response.body).to include(I18n.t("imports.no_text"))
    end

    it "redirects to deck with alert when no valid pairs found" do
      post text_deck_import_path(deck), params: { text: "no separator here" }
      expect(response).to redirect_to(deck_path(deck))
      follow_redirect!
      expect(response.body).to include(I18n.t("imports.text_no_valid_pairs"))
    end

    it "redirects for another user's deck" do
      other_deck = create(:deck, user: create(:user))
      post text_deck_import_path(other_deck), params: { text: valid_text }
      expect(response).to redirect_to(decks_path)
    end

    it "creates cards using a custom row separator" do
      expect {
        post text_deck_import_path(deck), params: { text: "A\tB;C\tD", col_sep: "\t", row_sep: ";" }
      }.to change(Flashcard, :count).by(2)
    end
  end
end
