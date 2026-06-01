require "rails_helper"

RSpec.describe "Accounts#update", type: :request do
  let(:user) { create(:user) }

  describe "PATCH /account" do
    context "when authenticated" do
      before { sign_in(user) }

      context "updating profile" do
        it "updates display name" do
          patch account_path, params: { section: "profile", display_name: "Alex" }
          expect(user.reload.display_name).to eq("Alex")
          expect(response).to redirect_to(account_path)
        end

        it "clears display name when blank (falls back to email)" do
          user.update!(display_name: "Alex")
          patch account_path, params: { section: "profile", display_name: "" }
          expect(user.reload[:display_name]).to be_nil
          expect(response).to redirect_to(account_path)
        end

        it "rejects display name longer than 50 characters" do
          patch account_path, params: { section: "profile", display_name: "A" * 51 }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "attaches an avatar" do
          file = fixture_file_upload("spec/fixtures/files/test_avatar.png", "image/png")
          patch account_path, params: { section: "profile", avatar: file }
          expect(user.reload.avatar).to be_attached
          expect(response).to redirect_to(account_path)
        end

        it "hides photo when show_avatar is unchecked" do
          file = fixture_file_upload("spec/fixtures/files/test_avatar.png", "image/png")
          user.avatar.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_avatar.png")),
                             filename: "test.png", content_type: "image/png")
          patch account_path, params: { section: "profile", show_avatar: "0" }
          expect(user.reload.show_avatar).to be false
          expect(response).to redirect_to(account_path)
        end

        it "shows photo when show_avatar is checked" do
          user.update!(show_avatar: false)
          patch account_path, params: { section: "profile", show_avatar: "1" }
          expect(user.reload.show_avatar).to be true
          expect(response).to redirect_to(account_path)
        end
      end

      context "updating email" do
        it "updates email with correct current password" do
          patch account_path, params: { section: "email", email_address: "new@example.com", current_password: "password123" }
          expect(user.reload.email_address).to eq("new@example.com")
          expect(response).to redirect_to(account_path)
        end

        it "rejects update with wrong current password" do
          patch account_path, params: { section: "email", email_address: "new@example.com", current_password: "wrong" }
          expect(user.reload.email_address).not_to eq("new@example.com")
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "rejects invalid email format" do
          patch account_path, params: { section: "email", email_address: "not-an-email", current_password: "password123" }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "updating password" do
        it "updates password with correct current password" do
          patch account_path, params: {
            section: "password",
            password: "newpassword456",
            password_confirmation: "newpassword456",
            current_password: "password123"
          }
          expect(user.reload.authenticate("newpassword456")).to be_truthy
          expect(response).to redirect_to(account_path)
        end

        it "rejects update with wrong current password" do
          patch account_path, params: {
            section: "password",
            password: "newpassword456",
            password_confirmation: "newpassword456",
            current_password: "wrong"
          }
          expect(user.reload.authenticate("newpassword456")).to be_falsy
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "rejects mismatched password confirmation" do
          patch account_path, params: {
            section: "password",
            password: "newpassword456",
            password_confirmation: "different789",
            current_password: "password123"
          }
          expect(user.reload.authenticate("newpassword456")).to be_falsy
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "rejects password shorter than 8 characters" do
          patch account_path, params: {
            section: "password",
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
        patch account_path, params: { section: "email", email_address: "x@example.com", current_password: "password123" }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
