require "rails_helper"

RSpec.describe "FolderTags#delete_modal", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:tag)    { create(:folder_tag, folder: folder, name: "Grammar") }

  describe "GET /folders/:folder_id/tags/:id/delete_modal" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get delete_modal_folder_tag_path(folder, tag)
        expect(response).to have_http_status(:ok)
      end

      it "renders the delete title and the tag name" do
        get delete_modal_folder_tag_path(folder, tag)
        expect(response.body).to include(I18n.t("folders.tags_modal.delete_title"))
        expect(response.body).to include("Grammar")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get delete_modal_folder_tag_path(folder, tag)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get delete_modal_folder_tag_path(folder, tag)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
