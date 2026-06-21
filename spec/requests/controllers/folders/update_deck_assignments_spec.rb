require "rails_helper"

RSpec.describe "Folders#update_deck_assignments", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:deck_a) { create(:deck, user: user) }
  let(:deck_b) { create(:deck, user: user) }

  describe "PATCH /folders/:id/update_deck_assignments" do
    context "when authenticated as folder owner" do
      before { sign_in(user) }

      it "adds decks submitted that are not yet in the folder" do
        expect {
          patch update_deck_assignments_folder_path(folder),
                params: { deck_ids: [ deck_a.id, deck_b.id ] }
        }.to change(DeckFolder, :count).by(2)
      end

      it "removes user's own decks from the folder when not included in submission" do
        create(:deck_folder, deck: deck_a, folder: folder)
        create(:deck_folder, deck: deck_b, folder: folder)

        expect {
          patch update_deck_assignments_folder_path(folder),
                params: { deck_ids: [ deck_a.id ] }
        }.to change(DeckFolder, :count).by(-1)

        expect(DeckFolder.where(folder: folder).pluck(:deck_id)).to contain_exactly(deck_a.id)
      end

      it "does not remove decks belonging to other users" do
        other_user = create(:user)
        other_deck = create(:deck, user: other_user)
        create(:deck_folder, deck: other_deck, folder: folder)

        patch update_deck_assignments_folder_path(folder),
              params: { deck_ids: [] }

        expect(DeckFolder.where(folder: folder, deck: other_deck)).to exist
      end

      it "ignores deck IDs that belong to another user" do
        other_deck = create(:deck, user: create(:user))

        expect {
          patch update_deck_assignments_folder_path(folder),
                params: { deck_ids: [ other_deck.id ] }
        }.not_to change(DeckFolder, :count)
      end

      it "redirects to the folder after saving" do
        patch update_deck_assignments_folder_path(folder), params: { deck_ids: [] }
        expect(response).to redirect_to(folder_path(folder))
      end

      it "handles an empty submission (no deck_ids param)" do
        create(:deck_folder, deck: deck_a, folder: folder)

        expect {
          patch update_deck_assignments_folder_path(folder), params: {}
        }.to change(DeckFolder, :count).by(-1)
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away" do
        patch update_deck_assignments_folder_path(folder),
              params: { deck_ids: [ deck_a.id ] }
        expect(response).to redirect_to(decks_path)
      end

      it "does not modify folder assignments" do
        expect {
          patch update_deck_assignments_folder_path(folder),
                params: { deck_ids: [ deck_a.id ] }
        }.not_to change(DeckFolder, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch update_deck_assignments_folder_path(folder),
              params: { deck_ids: [ deck_a.id ] }
        expect(response).to redirect_to(login_path)
      end

      it "does not modify folder assignments" do
        expect {
          patch update_deck_assignments_folder_path(folder),
                params: { deck_ids: [ deck_a.id ] }
        }.not_to change(DeckFolder, :count)
      end
    end
  end
end
