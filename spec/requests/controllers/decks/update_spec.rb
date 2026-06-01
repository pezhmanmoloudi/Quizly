require "rails_helper"

RSpec.describe "Decks#update", type: :request do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }

  describe "PATCH /decks/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "updates the deck name and redirects" do
        patch deck_path(deck), params: { deck: { name: "Updated Name" } }
        expect(deck.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(deck_path(deck))
      end

      it "updates the language_code" do
        patch deck_path(deck), params: { deck: { language_code: "fr" } }
        expect(deck.reload.language_code).to eq("fr")
      end

      it "does not update with a blank name" do
        original_name = deck.name
        patch deck_path(deck), params: { deck: { name: "" } }
        expect(deck.reload.name).to eq(original_name)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "returns 404" do
        patch deck_path(deck), params: { deck: { name: "Hijacked" } }
        expect(response).to have_http_status(:not_found)
      end

      it "does not modify the deck" do
        original_name = deck.name
        patch deck_path(deck), params: { deck: { name: "Hijacked" } }
        expect(deck.reload.name).to eq(original_name)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch deck_path(deck), params: { deck: { name: "Test" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
