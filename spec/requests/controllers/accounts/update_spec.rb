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
          expect(response).to redirect_to(account_path(anchor: "profile"))
        end

        it "clears display name when blank (falls back to email)" do
          user.update!(display_name: "Alex")
          patch account_path, params: { section: "profile", display_name: "" }
          expect(user.reload[:display_name]).to be_nil
          expect(response).to redirect_to(account_path(anchor: "profile"))
        end

        it "rejects display name longer than 50 characters" do
          patch account_path, params: { section: "profile", display_name: "A" * 51 }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "attaches an avatar" do
          file = fixture_file_upload("spec/fixtures/files/test_avatar.png", "image/png")
          patch account_path, params: { section: "profile", avatar: file }
          expect(user.reload.avatar).to be_attached
          expect(response).to redirect_to(account_path(anchor: "profile"))
        end

        it "rejects a GIF upload" do
          file = fixture_file_upload("spec/fixtures/files/test_avatar.gif", "image/gif")
          patch account_path, params: { section: "profile", avatar: file }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(user.reload.avatar).not_to be_attached
        end

        it "rejects a PDF upload" do
          file = fixture_file_upload("spec/fixtures/files/test_avatar.pdf", "application/pdf")
          patch account_path, params: { section: "profile", avatar: file }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(user.reload.avatar).not_to be_attached
        end

        it "rejects an oversized JPEG" do
          Tempfile.create([ "large_avatar", ".jpg" ]) do |f|
            soi    = "\xFF\xD8".b
            app0   = "\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00".b
            eoi    = "\xFF\xD9".b
            filler = ("X" * (5.megabytes + 512)).b
            f.binmode
            f.write(soi + app0 + filler + eoi)
            f.rewind
            file = Rack::Test::UploadedFile.new(f.path, "image/jpeg")
            patch account_path, params: { section: "profile", avatar: file }
            expect(response).to have_http_status(:unprocessable_entity)
            expect(user.reload.avatar).not_to be_attached
          end
        end
      end

      context "updating email" do
        it "updates email with correct current password" do
          patch account_path, params: { section: "email", email_address: "new@example.com", current_password: "password123" }
          expect(user.reload.email_address).to eq("new@example.com")
          expect(response).to redirect_to(account_path(anchor: "email"))
        end

        it "rejects update with wrong current password" do
          patch account_path, params: { section: "email", email_address: "new@example.com", current_password: "wrong" }
          expect(user.reload.email_address).not_to eq("new@example.com")
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders inline error for wrong current password" do
          patch account_path, params: { section: "email", email_address: "new@example.com", current_password: "wrong" }
          expect(response.body).to include('class="field-error"')
          expect(response.body).to include('data-server-error="true"')
        end

        it "does not render block-level form errors div on failure" do
          patch account_path, params: { section: "email", email_address: "new@example.com", current_password: "wrong" }
          expect(response.body).not_to include('class="form-errors"')
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
          expect(response).to redirect_to(account_path(anchor: "password"))
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

        it "renders inline error for mismatched password confirmation" do
          patch account_path, params: {
            section: "password",
            password: "newpassword456",
            password_confirmation: "different789",
            current_password: "password123"
          }
          expect(response.body).to include('class="field-error"')
          expect(response.body).to include('data-server-error="true"')
        end

        it "does not render block-level form errors div on failure" do
          patch account_path, params: {
            section: "password",
            password: "newpassword456",
            password_confirmation: "different789",
            current_password: "password123"
          }
          expect(response.body).not_to include('class="form-errors"')
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

        it "rejects blank password without changing the existing password" do
          patch account_path, params: {
            section: "password",
            password: "",
            password_confirmation: "",
            current_password: "password123"
          }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(user.reload.authenticate("password123")).to be_truthy
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
