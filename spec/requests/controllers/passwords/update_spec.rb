require "rails_helper"

RSpec.describe "Passwords#update", type: :request do
  let(:user) { create(:user) }

  describe "PATCH /reset-password/:token" do
    context "with a valid token and matching passwords" do
      it "updates the password" do
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        expect(user.reload.authenticate("newpassword123")).to be_truthy
      end

      it "redirects to login with a success notice" do
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq(I18n.t("passwords.reset"))
      end

      it "destroys all sessions for the user" do
        user.sessions.create!(user_agent: "UA", ip_address: "127.0.0.1")
        user.sessions.create!(user_agent: "UA2", ip_address: "127.0.0.2")
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        expect(user.reload.sessions.count).to eq(0)
      end

      it "does not destroy sessions belonging to other users" do
        other_user = create(:user)
        other_user.sessions.create!(user_agent: "UA", ip_address: "127.0.0.1")
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        expect(other_user.sessions.count).to eq(1)
      end
    end

    context "with mismatched passwords" do
      it "does not update the password" do
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "newpassword123", password_confirmation: "different123" }
        expect(user.reload.authenticate("newpassword123")).to be_falsy
      end

      it "redirects back to the reset form with an alert" do
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "newpassword123", password_confirmation: "different123" }
        expect(response).to redirect_to(reset_password_path(token))
        expect(flash[:alert]).to eq(I18n.t("passwords.mismatch"))
      end
    end

    context "with a password that is too short" do
      it "does not update the password" do
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "short", password_confirmation: "short" }
        expect(user.reload.authenticate("short")).to be_falsy
      end

      it "redirects back to the reset form with an alert" do
        token = user.password_reset_token
        patch reset_password_path(token), params: { password: "short", password_confirmation: "short" }
        expect(response).to redirect_to(reset_password_path(token))
        expect(flash[:alert]).to eq(I18n.t("passwords.mismatch"))
      end
    end

    context "with an invalid (tampered) token" do
      it "redirects to forgot password page with alert" do
        patch reset_password_path("bad-token"), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        expect(response).to redirect_to(forgot_password_path)
        expect(flash[:alert]).to eq(I18n.t("passwords.invalid"))
      end
    end

    context "with an expired token" do
      it "redirects to forgot password page with alert" do
        token = user.password_reset_token
        travel 16.minutes do
          patch reset_password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
          expect(response).to redirect_to(forgot_password_path)
          expect(flash[:alert]).to eq(I18n.t("passwords.invalid"))
        end
      end
    end
  end
end
