require "rails_helper"

RSpec.describe "Folders#index", type: :request do
  let(:user) { create(:user) }

  describe "GET /folders" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get folders_path
        expect(response).to have_http_status(:ok)
      end

      it "shows only folders belonging to the current user" do
        create(:folder, user: user, name: "Mine")
        create(:folder, user: create(:user), name: "Theirs")
        get folders_path
        expect(response.body).to include("Mine")
        expect(response.body).not_to include("Theirs")
      end

      it "shows empty state when user has no folders" do
        get folders_path
        expect(response.body).to include(I18n.t("folders.index.empty"))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get folders_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
