require "rails_helper"

RSpec.describe "Accounts#destroy_avatar", type: :request do
  let(:user) { create(:user) }

  def attach_avatar(u = user)
    u.avatar.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/test_avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
  end

  describe "DELETE /account/avatar" do
    context "when authenticated" do
      before { sign_in(user) }

      it "removes the avatar" do
        attach_avatar
        delete avatar_account_path
        expect(user.reload.avatar).not_to be_attached
        expect(response).to redirect_to(account_path)
      end

      it "succeeds even if no avatar is attached" do
        delete avatar_account_path
        expect(response).to redirect_to(account_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login without removing the avatar" do
        attach_avatar
        delete avatar_account_path
        expect(response).to redirect_to(login_path)
        expect(user.reload.avatar).to be_attached
      end
    end
  end
end
