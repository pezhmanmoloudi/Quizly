require "rails_helper"

RSpec.describe "FolderTags#update", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:tag)    { create(:folder_tag, folder: folder, name: "Grammar") }
  let(:deck)   { create(:deck, user: user) }

  before { create(:deck_folder, deck: deck, folder: folder) }

  describe "PATCH /folders/:folder_id/tags/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "renames the tag" do
        patch folder_tag_path(folder, tag), params: { folder_tag: { name: "Vocabulary" } }
        expect(tag.reload.name).to eq("Vocabulary")
      end

      it "returns a Turbo Stream response" do
        patch folder_tag_path(folder, tag),
              params: { folder_tag: { name: "Vocabulary" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "does not rename the tag" do
        patch folder_tag_path(folder, tag), params: { folder_tag: { name: "Hacked" } }
        expect(tag.reload.name).to eq("Grammar")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch folder_tag_path(folder, tag), params: { folder_tag: { name: "Vocabulary" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
