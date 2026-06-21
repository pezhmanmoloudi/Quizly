require "rails_helper"

RSpec.describe "Folders#add_decks_modal", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }

  describe "GET /folders/:id/add_decks_modal" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns ok" do
        get add_decks_modal_folder_path(folder)
        expect(response).to have_http_status(:ok)
      end

      it "renders the modal inside a turbo frame" do
        get add_decks_modal_folder_path(folder)
        expect(response.body).to include('id="modal"')
      end

      it "scopes decks to current user" do
        other_deck = create(:deck, user: create(:user))
        get add_decks_modal_folder_path(folder)
        expect(response.body).not_to include(other_deck.name)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        get add_decks_modal_folder_path(folder)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get add_decks_modal_folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
