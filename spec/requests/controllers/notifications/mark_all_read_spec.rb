require "rails_helper"

RSpec.describe "Notifications#mark_all_read", type: :request do
  let(:user) { create(:user) }

  context "when authenticated" do
    before { sign_in(user) }

    it "marks all unread notifications as read and responds with turbo_stream" do
      create_list(:notification, 4, recipient: user, read: false)
      patch mark_all_read_notifications_path,
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(user.notifications.unread.count).to eq(0)
    end

    it "redirects to notifications_path for plain HTML requests" do
      patch mark_all_read_notifications_path
      expect(response).to redirect_to(notifications_path)
    end

    it "only marks the current user's notifications as read" do
      other_user_notification = create(:notification, read: false)
      create(:notification, recipient: user, read: false)
      patch mark_all_read_notifications_path,
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(other_user_notification.reload.read).to be false
    end

    it "responds successfully when there are no unread notifications" do
      create(:notification, :read, recipient: user)
      patch mark_all_read_notifications_path,
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "turbo stream response includes the dropdown header and correct targets" do
      create(:notification, recipient: user, read: false)
      patch mark_all_read_notifications_path,
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.body).to include(I18n.t("notifications.title"))
      expect(response.body).to include('target="notification-list"')
      expect(response.body).to include('target="notification-badge-inner"')
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      patch mark_all_read_notifications_path
      expect(response).to redirect_to(login_path)
    end
  end
end
