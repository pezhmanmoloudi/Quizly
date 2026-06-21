require "rails_helper"

RSpec.describe "FolderDeckAssignments#new", type: :request do
  let(:user)    { create(:user) }
  let(:deck)    { create(:deck, :public) }
  let!(:folder) { create(:folder, user: user) }

  describe "GET /folder_deck_assignments/new" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns ok" do
        get new_folder_deck_assignment_path(deck_id: deck.id)
        expect(response).to have_http_status(:ok)
      end

      it "renders the save modal inside a turbo frame" do
        get new_folder_deck_assignment_path(deck_id: deck.id)
        expect(response.body).to include('id="modal"')
        expect(response.body).to include("folder_deck_assignments")
      end

      it "includes user folders in the response" do
        get new_folder_deck_assignment_path(deck_id: deck.id)
        expect(response.body).to include(folder.name)
      end

      it "pre-checks folders the deck is already saved to" do
        create(:deck_folder, deck: deck, folder: folder)
        get new_folder_deck_assignment_path(deck_id: deck.id)
        expect(response.body).to include("checked")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_folder_deck_assignment_path(deck_id: deck.id)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
