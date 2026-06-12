require "rails_helper"

RSpec.describe "Notifications#badge", type: :request do
  let(:user) { create(:user) }

  context "when authenticated" do
    before { sign_in(user) }

    it "reflects the unread count" do
      create_list(:notification, 3, recipient: user, read: false)
      create(:notification, :read, recipient: user)
      get badge_notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("3")
    end

    it "renders no badge markup when count is zero" do
      get badge_notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("notif-badge")
    end

    it "shows 99+ when unread count exceeds 99" do
      create_list(:notification, 100, recipient: user, read: false)
      get badge_notifications_path
      expect(response.body).to include("99+")
      expect(response.body).not_to include(">100<")
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      get badge_notifications_path
      expect(response).to redirect_to(login_path)
    end
  end
end
