require "rails_helper"

RSpec.describe "Folders#destroy", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }

  describe "DELETE /folders/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "destroys the folder" do
        folder
        expect { delete folder_path(folder) }.to change(Folder, :count).by(-1)
      end

      it "redirects to folders index on HTML format" do
        delete folder_path(folder)
        expect(response).to redirect_to(folders_path)
      end

      it "returns a Turbo Stream response" do
        delete folder_path(folder),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "removes associated deck_folder join records" do
        deck = create(:deck, user: user)
        create(:deck_folder, deck: deck, folder: folder)
        expect { delete folder_path(folder) }.to change(DeckFolder, :count).by(-1)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away without destroying the folder" do
        folder
        expect { delete folder_path(folder) }.not_to change(Folder, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
