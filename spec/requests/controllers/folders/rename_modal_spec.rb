require "rails_helper"

RSpec.describe "Folders#rename_modal", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }

  describe "GET /folders/:id/rename_modal" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns ok" do
        get rename_modal_folder_path(folder)
        expect(response).to have_http_status(:ok)
      end

      it "renders the rename modal inside a turbo frame" do
        get rename_modal_folder_path(folder)
        expect(response.body).to include('id="modal"')
        expect(response.body).to include(folder.name)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get rename_modal_folder_path(folder)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get rename_modal_folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
