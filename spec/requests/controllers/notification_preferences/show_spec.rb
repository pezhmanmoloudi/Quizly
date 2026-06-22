require "rails_helper"

RSpec.describe "NotificationPreferences#show", type: :request do
  let(:user) { create(:user) }

  describe "GET /notification_preferences" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get notification_preferences_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get notification_preferences_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
