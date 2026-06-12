require "rails_helper"

RSpec.describe "Notifications#index", type: :request do
  let(:user) { create(:user) }

  context "when authenticated" do
    before { sign_in(user) }

    it "returns 200 with turbo-frame wrapper" do
      create(:notification, recipient: user)
      get notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("notification-list")
    end

    it "renders the empty state when no notifications exist" do
      get notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("notifications.empty"))
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      get notifications_path
      expect(response).to redirect_to(login_path)
    end
  end
end
