require "rails_helper"

RSpec.describe "FolderTags#destroy", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let!(:tag)   { create(:folder_tag, folder: folder, name: "Grammar") }
  let(:deck)   { create(:deck, user: user) }

  before { create(:deck_folder, deck: deck, folder: folder) }

  describe "DELETE /folders/:folder_id/tags/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "deletes the tag" do
        expect {
          delete folder_tag_path(folder, tag)
        }.to change(FolderTag, :count).by(-1)
      end

      it "removes its deck assignments" do
        create(:deck_folder_tag, folder_tag: tag, deck: deck)
        expect {
          delete folder_tag_path(folder, tag)
        }.to change(DeckFolderTag, :count).by(-1)
      end

      it "does not delete the underlying decks" do
        create(:deck_folder_tag, folder_tag: tag, deck: deck)
        expect {
          delete folder_tag_path(folder, tag)
        }.not_to change(Deck, :count)
      end

      it "returns a Turbo Stream response" do
        delete folder_tag_path(folder, tag),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "does not delete the tag" do
        expect {
          delete folder_tag_path(folder, tag)
        }.not_to change(FolderTag, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete folder_tag_path(folder, tag)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
