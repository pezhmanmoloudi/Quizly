require "rails_helper"

RSpec.describe "Users#following", type: :request do
  let(:viewer)       { create(:user) }
  let(:profile_user) { create(:user) }
  let(:followed)     { create(:user) }

  before { create(:follow, follower: profile_user, followed: followed) }

  describe "GET /users/:username/following" do
    context "when authenticated" do
      before { sign_in(viewer) }

      it "returns ok" do
        get following_user_path(profile_user)
        expect(response).to have_http_status(:ok)
      end

      it "lists users the profile owner follows" do
        get following_user_path(profile_user)
        expect(response.body).to include(followed.display_name)
      end

      it "does not list users the profile owner does not follow" do
        other = create(:user)
        get following_user_path(profile_user)
        expect(response.body).not_to include(other.display_name)
      end

      it "shows an empty state when the user follows nobody" do
        get following_user_path(viewer)
        expect(response.body).to include(I18n.t("follows.no_following"))
      end
    end

    context "when unauthenticated" do
      it "returns ok (public page)" do
        get following_user_path(profile_user)
        expect(response).to have_http_status(:ok)
      end

      it "lists followed users" do
        get following_user_path(profile_user)
        expect(response.body).to include(followed.display_name)
      end
    end

    context "with an unknown username" do
      it "redirects (ApplicationController rescues RecordNotFound as redirect)" do
        get following_user_path("nonexistent_xyz_123")
        expect(response).to be_redirect
      end
    end
  end
end
