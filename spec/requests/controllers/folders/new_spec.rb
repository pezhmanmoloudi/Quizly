require "rails_helper"

RSpec.describe "Folders#new", type: :request do
  let(:user) { create(:user) }

  describe "GET /folders/new" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns ok" do
        get new_folder_path
        expect(response).to have_http_status(:ok)
      end

      it "renders the create folder modal inside a turbo frame" do
        get new_folder_path
        expect(response.body).to include('id="modal"')
        expect(response.body).to include("Create Folder")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_folder_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
