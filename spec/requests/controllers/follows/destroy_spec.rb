require "rails_helper"

RSpec.describe "Follows#destroy", type: :request do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }

  context "when authenticated" do
    before do
      sign_in(follower)
      create(:follow, follower: follower, followed: followed)
    end

    it "destroys the follow record" do
      expect {
        delete user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Follow, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "responds with turbo_stream format" do
      delete user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "does not create an unfollow notification" do
      expect {
        delete user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change(Notification, :count)
    end

    it "cannot destroy another user's follow (redirected by not-found handler)" do
      other_follower = create(:user)
      sign_in(other_follower)
      expect {
        delete user_follow_path(followed), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change(Follow, :count)
      expect(response).to be_redirect
    end

    it "redirects to user profile for HTML requests" do
      delete user_follow_path(followed)
      expect(response).to redirect_to(user_path(followed))
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      delete user_follow_path(followed)
      expect(response).to redirect_to(login_path)
    end
  end
end
