require "rails_helper"

RSpec.describe "OmniauthCallbacks#github", type: :request do
  describe "GET /auth/github/callback" do
    let(:callback_path) { "/auth/github/callback" }

    context "with a new GitHub user" do
      before { mock_github_auth(uid: "new-uid", email: "newcomer@example.com", name: "New Comer") }

      it "creates the user, signs them in, and redirects to the dashboard" do
        expect { get callback_path }.to change(User, :count).by(1)

        user = User.find_by(github_uid: "new-uid")
        expect(user.email_address).to eq("newcomer@example.com")
        expect(response).to redirect_to(dashboard_url)
        expect(flash[:notice]).to eq(I18n.t("sessions.github.success"))
      end
    end

    context "with an existing user matched by github_uid" do
      let!(:user) { create(:user, github_uid: "existing-uid") }

      before { mock_github_auth(uid: "existing-uid", email: user.email_address) }

      it "signs in without creating a new user" do
        expect { get callback_path }.not_to change(User, :count)
        expect(response).to redirect_to(dashboard_url)
      end
    end

    context "with an existing user matched by email but no github_uid" do
      let!(:user) { create(:user, email_address: "linkme@example.com", github_uid: nil) }

      before { mock_github_auth(uid: "fresh-uid", email: "linkme@example.com") }

      it "links the github_uid to the existing account" do
        expect { get callback_path }.not_to change(User, :count)
        expect(user.reload.github_uid).to eq("fresh-uid")
        expect(response).to redirect_to(dashboard_url)
      end
    end

    context "with a missing or invalid auth hash" do
      before { clear_github_auth }

      it "redirects to login with the failure alert" do
        get callback_path
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(I18n.t("sessions.github.failure"))
      end
    end
  end
end
