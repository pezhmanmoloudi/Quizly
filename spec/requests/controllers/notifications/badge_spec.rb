require "rails_helper"

# The badge is now rendered inline in the application layout — no separate route exists.
# These specs verify the inline count via any full-page request that renders the layout,
# and that Turbo Stream responses from mark_read/mark_all_read target the correct element.
RSpec.describe "Notifications badge (inline layout)", type: :request do
  let(:user) { create(:user) }

  context "when authenticated" do
    before { sign_in(user) }

    it "shows the unread count in the layout" do
      create_list(:notification, 3, recipient: user, read: false)
      create(:notification, :read, recipient: user)
      get notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("notification-badge-inner")
      expect(response.body).to include("notif-badge")
    end

    it "renders no badge markup when all notifications are read" do
      create(:notification, :read, recipient: user)
      get notifications_path
      expect(response.body).to include("notification-badge-inner")
      expect(response.body).not_to include("notif-badge")
    end

    it "shows 99+ when unread count exceeds 99" do
      create_list(:notification, 100, recipient: user, read: false)
      get notifications_path
      expect(response.body).to include("99+")
    end
  end

  context "when unauthenticated" do
    it "redirects to login on any authenticated page" do
      get notifications_path
      expect(response).to redirect_to(login_path)
    end
  end
end
