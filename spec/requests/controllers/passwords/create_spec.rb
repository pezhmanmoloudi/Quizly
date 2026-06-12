require "rails_helper"

RSpec.describe "Passwords#create", type: :request do
  describe "POST /forgot-password" do
    context "when email exists" do
      let!(:user) { create(:user) }

      it "redirects to login with a notice" do
        post forgot_password_path, params: { email_address: user.email_address }
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq(I18n.t("passwords.sent"))
      end

      it "enqueues a password reset email" do
        expect {
          post forgot_password_path, params: { email_address: user.email_address }
        }.to have_enqueued_mail(PasswordsMailer, :reset).with(user)
      end
    end

    context "when email does not exist (enumeration safety)" do
      it "redirects to login with the same notice" do
        post forgot_password_path, params: { email_address: "nobody@example.com" }
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq(I18n.t("passwords.sent"))
      end

      it "does not enqueue any email" do
        expect {
          post forgot_password_path, params: { email_address: "nobody@example.com" }
        }.not_to have_enqueued_mail
      end
    end

    context "rate limiting" do
      before { ActionController::Base.cache_store.clear }

      it "allows requests up to the limit" do
        5.times do
          post forgot_password_path, params: { email_address: "test@example.com" }
          expect(response).to redirect_to(login_path)
        end
      end

      it "redirects with alert after exceeding the limit" do
        5.times { post forgot_password_path, params: { email_address: "test@example.com" } }
        post forgot_password_path, params: { email_address: "test@example.com" }
        expect(response).to redirect_to(forgot_password_url)
        expect(flash[:alert]).to eq(I18n.t("passwords.errors.rate_limited"))
      end
    end
  end
end
