require "rails_helper"

RSpec.describe "Decks#rotate_share_token", type: :request do
  let(:owner) { create(:user) }
  let(:deck)  { create(:deck, :unlisted, user: owner) }

  describe "PATCH /decks/:id/rotate_share_token" do
    context "when authenticated as owner" do
      before { sign_in(owner) }

      it "changes the share_token" do
        original_token = deck.share_token
        patch rotate_share_token_deck_path(deck)
        expect(deck.reload.share_token).not_to eq(original_token)
      end

      it "sets a non-blank share_token" do
        patch rotate_share_token_deck_path(deck)
        expect(deck.reload.share_token).to be_present
      end

      it "redirects to the edit page" do
        patch rotate_share_token_deck_path(deck)
        expect(response).to redirect_to(edit_deck_path(deck))
      end

      it "sets a flash notice" do
        patch rotate_share_token_deck_path(deck)
        follow_redirect!
        expect(response.body).to include("Share link regenerated")
      end

      it "works for non-unlisted decks too (token rotation is owner-only, no visibility restriction)" do
        private_deck = create(:deck, user: owner, visibility: "private")
        original_token = private_deck.share_token
        patch rotate_share_token_deck_path(private_deck)
        expect(private_deck.reload.share_token).not_to eq(original_token)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "returns 404" do
        patch rotate_share_token_deck_path(deck)
        expect(response).to have_http_status(:not_found)
      end

      it "does not change the share_token" do
        original_token = deck.share_token
        patch rotate_share_token_deck_path(deck)
        expect(deck.reload.share_token).to eq(original_token)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch rotate_share_token_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
