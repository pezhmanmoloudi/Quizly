require "rails_helper"

RSpec.describe "Sessions#create", type: :request do
  describe "POST /login" do
    let!(:user) { create(:user) }

    context "with valid credentials" do
      it "redirects to dashboard" do
        post login_path, params: { email_address: user.email_address, password: "password123" }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "with invalid credentials" do
      it "redirects to login with an alert" do
        post login_path, params: { email_address: user.email_address, password: "wrongpassword" }
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(I18n.t("sessions.errors.invalid"))
      end
    end

    context "rate limiting" do
      before { ActionController::Base.cache_store.clear }

      it "allows requests up to the limit" do
        10.times do
          post login_path, params: { email_address: user.email_address, password: "wrong" }
          expect(response).to redirect_to(login_path)
        end
      end

      it "redirects with alert after exceeding the limit" do
        10.times { post login_path, params: { email_address: user.email_address, password: "wrong" } }
        post login_path, params: { email_address: user.email_address, password: "wrong" }
        expect(response).to redirect_to(login_url)
        expect(flash[:alert]).to eq(I18n.t("sessions.errors.rate_limited"))
      end
    end
  end
end
