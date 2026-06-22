require "rails_helper"

RSpec.describe "Notifications#mark_read", type: :request do
  let(:user) { create(:user) }

  context "when authenticated" do
    before { sign_in(user) }

    it "marks the notification as read and responds with turbo_stream" do
      notification = create(:notification, recipient: user, read: false)
      patch mark_read_notification_path(notification),
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(notification.reload.read).to be true
    end

    it "redirects to notifications_path for plain HTML requests" do
      notification = create(:notification, recipient: user, read: false)
      patch mark_read_notification_path(notification)
      expect(response).to redirect_to(notifications_path)
    end

    it "cannot mark another user's notification as read" do
      other_notification = create(:notification, read: false)
      patch mark_read_notification_path(other_notification)
      expect(response).to redirect_to(decks_path)
    end

    it "turbo stream response replaces the notification element and updates the badge" do
      notification = create(:notification, recipient: user, read: false)
      patch mark_read_notification_path(notification),
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.body).to include("notification-#{notification.id}")
      expect(response.body).to include('target="notification-badge-inner"')
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      notification = create(:notification)
      patch mark_read_notification_path(notification)
      expect(response).to redirect_to(login_path)
    end
  end
end
