require "rails_helper"

RSpec.describe "Accounts#update", type: :request do
  let(:user) { create(:user) }

  describe "PATCH /account" do
    context "when authenticated" do
      before { sign_in(user) }

      context "updating email" do
        it "updates email with correct current password" do
          patch account_path, params: { email_address: "new@example.com", current_password: "password123" }
          expect(user.reload.email_address).to eq("new@example.com")
          expect(response).to redirect_to(account_path)
        end

        it "rejects update with wrong current password" do
          patch account_path, params: { email_address: "new@example.com", current_password: "wrong" }
          expect(user.reload.email_address).not_to eq("new@example.com")
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "rejects invalid email format" do
          patch account_path, params: { email_address: "not-an-email", current_password: "password123" }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "updating password" do
        it "updates password with correct current password" do
          patch account_path, params: {
            password: "newpassword456",
            password_confirmation: "newpassword456",
            current_password: "password123"
          }
          expect(user.reload.authenticate("newpassword456")).to be_truthy
          expect(response).to redirect_to(account_path)
        end

        it "rejects update with wrong current password" do
          patch account_path, params: {
            password: "newpassword456",
            password_confirmation: "newpassword456",
            current_password: "wrong"
          }
          expect(user.reload.authenticate("newpassword456")).to be_falsy
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "rejects mismatched password confirmation" do
          patch account_path, params: {
            password: "newpassword456",
            password_confirmation: "different789",
            current_password: "password123"
          }
          expect(user.reload.authenticate("newpassword456")).to be_falsy
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "rejects password shorter than 8 characters" do
          patch account_path, params: {
            password: "short",
            password_confirmation: "short",
            current_password: "password123"
          }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch account_path, params: { email_address: "x@example.com", current_password: "password123" }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
