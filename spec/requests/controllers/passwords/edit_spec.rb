require "rails_helper"

RSpec.describe "Passwords#edit", type: :request do
  let(:user) { create(:user) }

  describe "GET /reset-password/:token" do
    context "with a valid token" do
      it "returns 200" do
        get reset_password_path(user.password_reset_token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid (tampered) token" do
      it "redirects to forgot password page with alert" do
        get reset_password_path("invalid-token")
        expect(response).to redirect_to(forgot_password_path)
        expect(flash[:alert]).to eq(I18n.t("passwords.invalid"))
      end
    end

    context "with an expired token" do
      it "redirects to forgot password page with alert" do
        token = user.password_reset_token
        travel 16.minutes do
          get reset_password_path(token)
          expect(response).to redirect_to(forgot_password_path)
          expect(flash[:alert]).to eq(I18n.t("passwords.invalid"))
        end
      end
    end
  end
end
