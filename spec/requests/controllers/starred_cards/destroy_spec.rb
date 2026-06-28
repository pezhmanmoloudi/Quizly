require "rails_helper"

RSpec.describe "StarredCards#destroy", type: :request do
  let(:user)          { create(:user) }
  let(:deck)          { create(:deck, user: user) }
  let(:flashcard)     { create(:flashcard, deck: deck) }
  let(:card_progress) { create(:card_progress, user: user, flashcard: flashcard, starred: true) }

  describe "DELETE /card_progresses/:card_progress_id/starred_card" do
    context "when authenticated" do
      before { sign_in(user) }

      it "sets starred to false" do
        delete card_progress_starred_card_path(card_progress)
        expect(card_progress.reload.starred).to be false
      end

      it "returns turbo stream when Turbo Accept header is present" do
        delete card_progress_starred_card_path(card_progress),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "redirects for plain HTML requests" do
        delete card_progress_starred_card_path(card_progress)
        expect(response).to be_redirect
      end

      it "redirects when accessing another user's card progress (IDOR protection)" do
        other_user     = create(:user)
        other_deck     = create(:deck, user: other_user)
        other_card     = create(:flashcard, deck: other_deck)
        other_progress = create(:card_progress, user: other_user, flashcard: other_card, starred: true)

        delete card_progress_starred_card_path(other_progress)
        expect(response).to be_redirect
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete card_progress_starred_card_path(card_progress)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
