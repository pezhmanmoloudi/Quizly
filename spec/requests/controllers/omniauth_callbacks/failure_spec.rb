require "rails_helper"

RSpec.describe "OmniauthCallbacks#failure", type: :request do
  describe "GET /auth/failure" do
    it "redirects to login with the failure alert" do
      get "/auth/failure"
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq(I18n.t("sessions.errors.oauth_failure"))
    end
  end
end
