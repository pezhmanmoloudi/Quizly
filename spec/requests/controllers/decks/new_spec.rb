require "rails_helper"

RSpec.describe "Decks#new", type: :request do
  let(:user) { create(:user) }

  describe "GET /decks/new" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get new_deck_path
        expect(response).to have_http_status(:ok)
      end

      it "renders the deck form" do
        get new_deck_path
        expect(response.body).to include("New Deck")
      end

      it "pre-generates a share_token so the form can display the share URL" do
        get new_deck_path
        expect(response.body).to include("share_token")
      end

      it "renders the unlisted radio button" do
        get new_deck_path
        expect(response.body).to include('value="unlisted"')
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_deck_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
