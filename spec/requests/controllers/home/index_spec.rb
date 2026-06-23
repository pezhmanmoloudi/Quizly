require "rails_helper"

RSpec.describe "Home#index", type: :request do
  describe "GET /" do
    context "when not authenticated" do
      it "returns 200" do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it "renders the hero headline" do
        get root_path
        expect(response.body).to include("Study smarter, remember longer")
      end

      it "renders all five mode selector tabs" do
        get root_path
        %w[Flashcards Learn Study Test Match].each do |mode|
          expect(response.body).to include(mode)
        end
      end

      it "renders the mode selector grid" do
        get root_path
        expect(response.body).to include("home-modes-grid")
        expect(response.body).to include("home-mode-card")
      end

      it "shows Sign Up link" do
        get root_path
        expect(response.body).to include(signup_path)
      end

      it "shows featured public decks when they exist" do
        create(:deck, :public, name: "Featured Deck")
        get root_path
        expect(response.body).to include("Featured Deck")
      end
    end

    context "when authenticated" do
      it "redirects to dashboard" do
        sign_in(create(:user))
        get root_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
