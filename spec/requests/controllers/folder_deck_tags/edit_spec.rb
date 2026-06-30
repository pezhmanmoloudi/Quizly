require "rails_helper"

RSpec.describe "FolderDeckTags#edit", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:deck)   { create(:deck, user: user, name: "Vocab") }
  let(:tag)    { create(:folder_tag, folder: folder, name: "Grammar") }

  before { create(:deck_folder, deck: deck, folder: folder) }

  describe "GET /folders/:folder_id/deck_tags/:id/edit" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get edit_folder_deck_tag_path(folder, deck)
        expect(response).to have_http_status(:ok)
      end

      it "lists the folder's tags as options" do
        tag
        get edit_folder_deck_tag_path(folder, deck)
        expect(response.body).to include("Grammar")
      end

      it "checks tags already applied to the deck" do
        create(:deck_folder_tag, folder_tag: tag, deck: deck)
        get edit_folder_deck_tag_path(folder, deck)
        expect(response.body).to match(/value="#{tag.id}"[^>]*checked/)
      end

      it "shows a hint when the folder has no tags" do
        get edit_folder_deck_tag_path(folder, deck)
        expect(response.body).to include(I18n.t("folders.deck_tags_modal.no_tags"))
      end

      it "rejects a deck that is not in the folder" do
        other_deck = create(:deck, user: user)
        get edit_folder_deck_tag_path(folder, other_deck)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get edit_folder_deck_tag_path(folder, deck)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get edit_folder_deck_tag_path(folder, deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
