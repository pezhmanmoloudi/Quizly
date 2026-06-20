require "rails_helper"

RSpec.describe "Folders#show", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user, name: "Spanish") }

  describe "GET /folders/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get folder_path(folder)
        expect(response).to have_http_status(:ok)
      end

      it "displays the folder name" do
        get folder_path(folder)
        expect(response.body).to include("Spanish")
      end

      it "shows decks in the folder" do
        deck = create(:deck, user: user, name: "Vocab")
        create(:deck_folder, deck: deck, folder: folder)
        get folder_path(folder)
        expect(response.body).to include("Vocab")
      end

      it "shows empty state when no decks" do
        get folder_path(folder)
        expect(response.body).to include(I18n.t("folders.show.empty"))
      end

      it "renders rename and delete options" do
        get folder_path(folder)
        expect(response.body).to include(I18n.t("folders.show.rename"))
        expect(response.body).to include(I18n.t("folders.show.delete"))
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away when folder belongs to a different user" do
        get folder_path(folder)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
