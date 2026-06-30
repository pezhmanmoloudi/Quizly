require "rails_helper"

RSpec.describe "Folders#tags_modal", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user, name: "Spanish") }

  describe "GET /folders/:id/tags_modal" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get tags_modal_folder_path(folder)
        expect(response).to have_http_status(:ok)
      end

      it "renders the modal title" do
        get tags_modal_folder_path(folder)
        expect(response.body).to include(I18n.t("folders.tags_modal.title"))
      end

      it "lists existing tags" do
        create(:folder_tag, folder: folder, name: "Grammar")
        get tags_modal_folder_path(folder)
        expect(response.body).to include("Grammar")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get tags_modal_folder_path(folder)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get tags_modal_folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
