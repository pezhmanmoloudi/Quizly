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
        expect(response.body).to include("Learn anything")
      end

      it "shows Sign Up and Sign In links" do
        get root_path
        expect(response.body).to include(signup_path)
        expect(response.body).to include(login_path)
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
