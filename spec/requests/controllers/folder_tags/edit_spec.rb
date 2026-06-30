require "rails_helper"

RSpec.describe "FolderTags#edit", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:tag)    { create(:folder_tag, folder: folder, name: "Grammar") }

  describe "GET /folders/:folder_id/tags/:id/edit" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get edit_folder_tag_path(folder, tag)
        expect(response).to have_http_status(:ok)
      end

      it "renders the edit title and prefilled name" do
        get edit_folder_tag_path(folder, tag)
        expect(response.body).to include(I18n.t("folders.tags_modal.edit_title"))
        expect(response.body).to include('value="Grammar"')
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get edit_folder_tag_path(folder, tag)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get edit_folder_tag_path(folder, tag)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
