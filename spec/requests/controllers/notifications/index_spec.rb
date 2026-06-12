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

    it "renders notifications most recent first" do
      old_notif = create(:notification, recipient: user, created_at: 2.days.ago)
      new_notif = create(:notification, recipient: user, created_at: 1.hour.ago)
      get notifications_path
      expect(response.body.index("notification-#{new_notif.id}"))
        .to be < response.body.index("notification-#{old_notif.id}")
    end

    it "renders at most 20 notifications" do
      create_list(:notification, 25, recipient: user)
      get notifications_path
      expect(response.body.scan(/id="notification-\d+"/).length).to eq(20)
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      get notifications_path
      expect(response).to redirect_to(login_path)
    end
  end
end
