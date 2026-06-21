require "rails_helper"

RSpec.describe "FolderDeckAssignments#create", type: :request do
  let(:user)    { create(:user) }
  let(:folder1) { create(:folder, user: user) }
  let(:folder2) { create(:folder, user: user) }
  let(:deck)    { create(:deck, :public) }

  describe "POST /folder_deck_assignments" do
    context "when authenticated" do
      before { sign_in(user) }

      it "adds the deck to the specified folders" do
        expect {
          post folder_deck_assignments_path,
               params: { deck_id: deck.id, folder_ids: [folder1.id, folder2.id] }
        }.to change(DeckFolder, :count).by(2)
      end

      it "returns a Turbo Stream response" do
        post folder_deck_assignments_path,
             params: { deck_id: deck.id, folder_ids: [folder1.id] },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "redirects back on HTML format" do
        post folder_deck_assignments_path,
             params: { deck_id: deck.id, folder_ids: [folder1.id] }
        expect(response).to redirect_to(explore_path)
      end

      it "silently skips folders not owned by the user" do
        other_folder = create(:folder, user: create(:user))
        expect {
          post folder_deck_assignments_path,
               params: { deck_id: deck.id, folder_ids: [other_folder.id] }
        }.not_to change(DeckFolder, :count)
      end

      it "does not duplicate if deck already in folder" do
        create(:deck_folder, deck: deck, folder: folder1)
        expect {
          post folder_deck_assignments_path,
               params: { deck_id: deck.id, folder_ids: [folder1.id] }
        }.not_to change(DeckFolder, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post folder_deck_assignments_path,
             params: { deck_id: deck.id, folder_ids: [folder1.id] }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
