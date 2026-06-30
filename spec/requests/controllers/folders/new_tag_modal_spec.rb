require "rails_helper"

RSpec.describe "Folders#new_tag_modal", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }

  describe "GET /folders/:id/new_tag_modal" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get new_tag_modal_folder_path(folder)
        expect(response).to have_http_status(:ok)
      end

      it "renders the new-tag title and name field" do
        get new_tag_modal_folder_path(folder)
        expect(response.body).to include(I18n.t("folders.tags_modal.add_title"))
        expect(response.body).to include('name="folder_tag[name]"')
      end

      it "shows recommended tag suggestions" do
        get new_tag_modal_folder_path(folder)
        expect(response.body).to include(I18n.t("folders.tags_modal.recommended_label"))
      end

      it "lists current tags as quick-pick chips" do
        create(:folder_tag, folder: folder, name: "Grammar")
        get new_tag_modal_folder_path(folder)
        expect(response.body).to include("folder-#{folder.id}-tag-chips")
        expect(response.body).to include("Grammar")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get new_tag_modal_folder_path(folder)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_tag_modal_folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
