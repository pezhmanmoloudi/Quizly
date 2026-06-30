require "rails_helper"

RSpec.describe "FolderDeckTags#update", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:deck)   { create(:deck, user: user) }
  let(:tag)    { create(:folder_tag, folder: folder, name: "Grammar") }

  before { create(:deck_folder, deck: deck, folder: folder) }

  describe "PATCH /folders/:folder_id/deck_tags/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "tags the deck" do
        expect {
          patch folder_deck_tag_path(folder, deck), params: { tag_ids: [tag.id] }
        }.to change(DeckFolderTag, :count).by(1)
      end

      it "removes tags not in the request" do
        create(:deck_folder_tag, folder_tag: tag, deck: deck)
        expect {
          patch folder_deck_tag_path(folder, deck), params: { tag_ids: [] }
        }.to change(DeckFolderTag, :count).by(-1)
      end

      it "ignores tags from another folder" do
        foreign_tag = create(:folder_tag, folder: create(:folder, user: user))
        expect {
          patch folder_deck_tag_path(folder, deck), params: { tag_ids: [foreign_tag.id] }
        }.not_to change(DeckFolderTag, :count)
      end

      it "does not create or delete decks" do
        expect {
          patch folder_deck_tag_path(folder, deck), params: { tag_ids: [tag.id] }
        }.not_to change(Deck, :count)
      end

      it "returns a Turbo Stream response" do
        patch folder_deck_tag_path(folder, deck),
              params: { tag_ids: [tag.id] },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "does not change tags" do
        expect {
          patch folder_deck_tag_path(folder, deck), params: { tag_ids: [tag.id] }
        }.not_to change(DeckFolderTag, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch folder_deck_tag_path(folder, deck), params: { tag_ids: [tag.id] }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
