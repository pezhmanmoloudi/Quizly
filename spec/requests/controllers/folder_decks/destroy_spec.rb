require "rails_helper"

RSpec.describe "FolderDecks#destroy", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:deck)   { create(:deck, user: user) }

  before { create(:deck_folder, deck: deck, folder: folder) }

  describe "DELETE /folders/:folder_id/deck" do
    context "when authenticated as folder owner" do
      before { sign_in(user) }

      it "removes the deck from the folder" do
        expect {
          delete folder_deck_path(folder), params: { deck_id: deck.id }
        }.to change(DeckFolder, :count).by(-1)
      end

      it "returns a Turbo Stream response" do
        delete folder_deck_path(folder),
               params: { deck_id: deck.id },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "redirects to the folder on HTML format" do
        delete folder_deck_path(folder), params: { deck_id: deck.id }
        expect(response).to redirect_to(folder_path(folder))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete folder_deck_path(folder), params: { deck_id: deck.id }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
