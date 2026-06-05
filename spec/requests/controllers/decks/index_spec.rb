require "rails_helper"

RSpec.describe "Decks#index", type: :request do
  let(:user) { create(:user) }

  describe "GET /decks" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get decks_path
        expect(response).to have_http_status(:ok)
      end

      it "shows only decks belonging to the current user" do
        own_deck   = create(:deck, user: user, name: "My Deck")
        other_deck = create(:deck, user: create(:user), name: "Other Deck")
        get decks_path
        expect(response.body).to include("My Deck")
        expect(response.body).not_to include("Other Deck")
      end

      it "shows empty state when user has no decks" do
        get decks_path
        expect(response.body).to include("No decks yet")
      end

      it "renders sort dropdown" do
        get decks_path
        expect(response.body).to include("auto-submit")
      end

      it "sorts decks alphabetically with sort=az" do
        create(:deck, user: user, name: "Zebra")
        create(:deck, user: user, name: "Apple")
        get decks_path, params: { sort: "az" }
        expect(response.body.index("Apple")).to be < response.body.index("Zebra")
      end

      it "defaults to recent sort without sort param" do
        get decks_path
        expect(response).to have_http_status(:ok)
      end

      it "accepts most_due sort param without error" do
        create(:deck, user: user)
        get decks_path, params: { sort: "most_due" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get decks_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
