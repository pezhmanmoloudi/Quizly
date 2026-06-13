require "rails_helper"

RSpec.describe "SharedDecks#show", type: :request do
  let(:owner) { create(:user) }
  let(:deck)  { create(:deck, :unlisted, user: owner, name: "Secret Deck") }

  describe "GET /share/:token" do
    context "with a valid token" do
      it "returns 200" do
        get shared_deck_path(deck.share_token)
        expect(response).to have_http_status(:ok)
      end

      it "renders the deck name" do
        get shared_deck_path(deck.share_token)
        expect(response.body).to include("Secret Deck")
      end

      it "works without authentication" do
        get shared_deck_path(deck.share_token)
        expect(response).to have_http_status(:ok)
      end

      it "stores share_auth in the session" do
        get shared_deck_path(deck.share_token)
        expect(session["deck_share_#{deck.id}"]).to be true
      end

      it "allows subsequent access to the deck via normal route" do
        get shared_deck_path(deck.share_token)
        get deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "sets X-Robots-Tag: noindex" do
        get shared_deck_path(deck.share_token)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex")
      end
    end

    context "with an invalid token" do
      it "returns 404" do
        get shared_deck_path("not-a-real-token")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a token belonging to a non-unlisted deck" do
      it "returns 404" do
        public_deck = create(:deck, :everyone, user: owner)
        get shared_deck_path(public_deck.share_token)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
