require "rails_helper"

RSpec.describe "Decks#unsave", type: :request do
  let(:owner) { create(:user) }
  let(:saver) { create(:user) }
  let(:deck)  { create(:deck, :public, user: owner) }

  describe "DELETE /decks/:id/unsave" do
    context "when authenticated and deck is in library" do
      before do
        sign_in(saver)
        create(:library_item, user: saver, deck: deck)
      end

      it "destroys the LibraryItem" do
        expect { delete unsave_deck_path(deck) }.to change { LibraryItem.count }.by(-1)
      end

      it "redirects to the deck with a notice" do
        delete unsave_deck_path(deck)
        follow_redirect!
        expect(response.body).to include(I18n.t("decks.action.unsaved"))
      end
    end

    context "when deck is not in library" do
      before { sign_in(saver) }

      it "redirects to the deck with an alert" do
        delete unsave_deck_path(deck)
        expect(response).to redirect_to(deck_path(deck))
        follow_redirect!
        expect(response.body).to include(I18n.t("decks.action.not_in_library"))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete unsave_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
