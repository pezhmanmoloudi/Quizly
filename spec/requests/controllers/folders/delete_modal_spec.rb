require "rails_helper"

RSpec.describe "Folders#delete_modal", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }

  describe "GET /folders/:id/delete_modal" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns ok" do
        get delete_modal_folder_path(folder)
        expect(response).to have_http_status(:ok)
      end

      it "renders the delete confirmation modal inside a turbo frame" do
        get delete_modal_folder_path(folder)
        expect(response.body).to include('id="modal"')
        expect(response.body).to include("btn--danger")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get delete_modal_folder_path(folder)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get delete_modal_folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
