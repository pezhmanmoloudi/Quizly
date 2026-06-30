require "rails_helper"

RSpec.describe "FolderTags#create", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:deck)   { create(:deck, user: user) }

  before { create(:deck_folder, deck: deck, folder: folder) }

  describe "POST /folders/:folder_id/tags" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "creates a tag" do
        expect {
          post folder_tags_path(folder), params: { folder_tag: { name: "Grammar" } }
        }.to change(folder.folder_tags, :count).by(1)
      end

      it "does not create or duplicate decks" do
        expect {
          post folder_tags_path(folder), params: { folder_tag: { name: "Grammar" } }
        }.not_to change(Deck, :count)
      end

      it "returns a Turbo Stream response" do
        post folder_tags_path(folder),
             params: { folder_tag: { name: "Grammar" } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "rejects a blank name" do
        expect {
          post folder_tags_path(folder), params: { folder_tag: { name: "" } }
        }.not_to change(FolderTag, :count)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "does not create a tag" do
        expect {
          post folder_tags_path(folder), params: { folder_tag: { name: "Grammar" } }
        }.not_to change(FolderTag, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post folder_tags_path(folder), params: { folder_tag: { name: "Grammar" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
