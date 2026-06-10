require "rails_helper"

RSpec.describe "Accounts#show", type: :request do
  let(:user) { create(:user) }

  describe "GET /account" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get account_path
        expect(response).to have_http_status(:ok)
      end

      it "renders the three settings sections" do
        get account_path
        expect(response.body).to include('value="profile"')
        expect(response.body).to include('value="email"')
        expect(response.body).to include('value="password"')
      end

      it "renders the profile section with user info" do
        get account_path
        expect(response.body).to include(user.display_name)
        expect(response.body).to include(user.email_address)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get account_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
