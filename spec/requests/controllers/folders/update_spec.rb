require "rails_helper"

RSpec.describe "Folders#update", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }

  describe "PATCH /folders/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "updates the folder name" do
        patch folder_path(folder), params: { folder: { name: "Updated Name" } }
        expect(folder.reload.name).to eq("Updated Name")
      end

      it "returns a Turbo Stream response on success" do
        patch folder_path(folder),
              params: { folder: { name: "Updated Name" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "redirects to folder on HTML success" do
        patch folder_path(folder), params: { folder: { name: "Updated Name" } }
        expect(response).to redirect_to(folder_path(folder))
      end

      it "renders rename modal with unprocessable_entity on blank name" do
        patch folder_path(folder), params: { folder: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("turbo-frame")
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away without modifying the folder" do
        original = folder.name
        patch folder_path(folder), params: { folder: { name: "Hijacked" } }
        expect(response).to redirect_to(decks_path)
        expect(folder.reload.name).to eq(original)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch folder_path(folder), params: { folder: { name: "Test" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
