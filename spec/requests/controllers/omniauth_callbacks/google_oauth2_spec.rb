require "rails_helper"

RSpec.describe "OmniauthCallbacks#google_oauth2", type: :request do
  describe "GET /auth/google_oauth2/callback" do
    let(:callback_path) { "/auth/google_oauth2/callback" }

    context "with a new Google user" do
      before { mock_google_auth(uid: "new-uid", email: "newcomer@example.com", name: "New Comer") }

      it "creates the user, signs them in, and redirects to the dashboard" do
        expect { get callback_path }.to change(User, :count).by(1)

        user = User.find_by(google_uid: "new-uid")
        expect(user.email_address).to eq("newcomer@example.com")
        expect(response).to redirect_to(dashboard_url)
        expect(flash[:notice]).to eq(I18n.t("sessions.google.success"))
      end
    end

    context "with an existing user matched by google_uid" do
      let!(:user) { create(:user, google_uid: "existing-uid") }

      before { mock_google_auth(uid: "existing-uid", email: user.email_address) }

      it "signs in without creating a new user" do
        expect { get callback_path }.not_to change(User, :count)
        expect(response).to redirect_to(dashboard_url)
      end
    end

    context "with an existing user matched by email but no google_uid" do
      let!(:user) { create(:user, email_address: "linkme@example.com", google_uid: nil) }

      before { mock_google_auth(uid: "fresh-uid", email: "linkme@example.com") }

      it "links the google_uid to the existing account" do
        expect { get callback_path }.not_to change(User, :count)
        expect(user.reload.google_uid).to eq("fresh-uid")
        expect(response).to redirect_to(dashboard_url)
      end
    end

    context "with a missing or invalid auth hash" do
      before { clear_google_auth }

      it "redirects to login with the failure alert" do
        get callback_path
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(I18n.t("sessions.google.failure"))
      end
    end
  end
end
