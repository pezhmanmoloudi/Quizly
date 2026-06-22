require "rails_helper"

RSpec.describe "Follows#create", type: :request do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }

  context "when authenticated" do
    before { sign_in(follower) }

    it "creates a follow record" do
      expect {
        post user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Follow, :count).by(1)
      expect(response).to have_http_status(:ok)
    end

    it "responds with turbo_stream format" do
      post user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "creates a followed notification for the followed user when in_app_follows is true" do
      followed.notification_preference.update!(in_app_follows: true)
      expect {
        post user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      expect(notification.recipient).to eq(followed)
      expect(notification.actor).to eq(follower)
      expect(notification.event_type).to eq("followed")
    end

    it "does not create a notification when in_app_follows is false" do
      followed.notification_preference.update!(in_app_follows: false)
      expect {
        post user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change(Notification, :count)
    end

    it "handles a duplicate follow gracefully without raising an error" do
      create(:follow, follower: follower, followed: followed)
      post user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "does not create a duplicate follow record" do
      create(:follow, follower: follower, followed: followed)
      expect {
        post user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change(Follow, :count)
    end

    it "rejects a self-follow attempt" do
      post user_follow_path(follower), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(Follow.where(follower: follower, followed: follower)).to be_empty
    end

    it "redirects to user profile for HTML requests" do
      post user_follow_path(followed)
      expect(response).to redirect_to(user_path(followed))
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      post user_follow_path(followed)
      expect(response).to redirect_to(login_path)
    end
  end
end
