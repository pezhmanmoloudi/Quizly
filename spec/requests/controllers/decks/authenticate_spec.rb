require "rails_helper"

RSpec.describe "Decks#authenticate", type: :request do
  let(:owner) { create(:user) }
  let(:deck)  { create(:deck, :password_protected, user: owner) }

  describe "POST /decks/:id/authenticate" do
    context "with the correct password" do
      it "redirects to the deck" do
        post authenticate_deck_path(deck), params: { access_password: "secret123" }
        expect(response).to redirect_to(deck_path(deck))
      end

      it "allows the deck to be viewed after authentication" do
        post authenticate_deck_path(deck), params: { access_password: "secret123" }
        get deck_path(deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an incorrect password" do
      it "re-renders the unlock page with 422" do
        post authenticate_deck_path(deck), params: { access_password: "wrongpass" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Password Required")
      end

      it "does not grant access to the deck" do
        post authenticate_deck_path(deck), params: { access_password: "wrongpass" }
        get deck_path(deck)
        expect(response).to redirect_to(unlock_deck_path(deck))
      end
    end

    context "for a deck with password_users edit permission" do
      let(:pw_edit_deck) { create(:deck, :editable_by_password, user: owner) }

      it "grants content access (cards) after correct password when user is authenticated" do
        editor = create(:user)
        sign_in(editor)
        post authenticate_deck_path(pw_edit_deck), params: { access_password: "secret123" }
        get cards_deck_path(pw_edit_deck)
        expect(response).to have_http_status(:ok)
      end

      it "does not grant admin access (edit settings) after correct password" do
        editor = create(:user)
        sign_in(editor)
        post authenticate_deck_path(pw_edit_deck), params: { access_password: "secret123" }
        get edit_deck_path(pw_edit_deck)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
