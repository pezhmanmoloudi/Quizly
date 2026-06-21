require "rails_helper"

RSpec.describe "Folders#create", type: :request do
  let(:user) { create(:user) }

  describe "POST /folders" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a folder with the given name" do
        expect {
          post folders_path, params: { folder: { name: "Spanish" } }
        }.to change(Folder, :count).by(1)
        expect(Folder.last.name).to eq("Spanish")
      end

      it "assigns the folder to the current user" do
        post folders_path, params: { folder: { name: "Spanish" } }
        expect(Folder.last.user).to eq(user)
      end

      it "returns a Turbo Stream response on success" do
        post folders_path,
             params: { folder: { name: "Spanish" } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "redirects to the folder on HTML success" do
        post folders_path, params: { folder: { name: "Spanish" } }
        expect(response).to redirect_to(folder_path(Folder.last))
      end

      it "renders the create modal with unprocessable_entity on blank name" do
        expect {
          post folders_path, params: { folder: { name: "" } }
        }.not_to change(Folder, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("turbo-frame")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post folders_path, params: { folder: { name: "Spanish" } }
        expect(response).to redirect_to(login_path)
      end

      it "does not create a folder" do
        expect {
          post folders_path, params: { folder: { name: "Spanish" } }
        }.not_to change(Folder, :count)
      end
    end
  end
end
