require "rails_helper"

RSpec.describe "Dashboard#index", type: :request do
  let(:user) { create(:user) }

  describe "GET /dashboard" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it "displays the user's display name in the hero" do
        get dashboard_path
        expect(response.body).to include(user.display_name)
      end

      it "shows total deck count" do
        create_list(:deck, 3, user: user)
        get dashboard_path
        expect(response.body).to include("3")
      end

      it "shows only decks belonging to the current user" do
        own_deck   = create(:deck, user: user, name: "My Deck")
        other_deck = create(:deck, user: create(:user), name: "Stranger's Deck")
        get dashboard_path
        expect(response.body).to include("My Deck")
        expect(response.body).not_to include("Stranger's Deck")
      end

      it "shows at most 4 recent deck tiles" do
        create_list(:deck, 6, user: user)
        get dashboard_path
        # Each deck tile renders exactly one deck-tile__name element
        tile_count = response.body.scan("deck-tile__name").count
        expect(tile_count).to eq(4)
      end

      it "shows the New Deck CTA tile" do
        get dashboard_path
        expect(response.body).to include("New Deck")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get dashboard_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
