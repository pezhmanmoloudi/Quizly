require "rails_helper"

RSpec.describe "Flashcards#destroy", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck) }

  describe "DELETE /flashcards/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "destroys the flashcard and redirects to the deck" do
        flashcard
        expect {
          delete flashcard_path(flashcard)
        }.to change(Flashcard, :count).by(-1)
        expect(response).to redirect_to(deck_path(deck, page: 1, items: 10))
      end

      it "soft-deletes the flashcard immediately and defers item cleanup to the hard-delete job" do
        learn_session = create(:learn_session, user: user, deck: deck)
        item = create(:learn_session_item, learn_session: learn_session, flashcard: flashcard)

        expect {
          delete flashcard_path(flashcard)
        }.to change(Flashcard, :count).by(-1)

        # learn_session_item is NOT removed until the hard-delete job runs
        expect(LearnSessionItem.exists?(item.id)).to be true

        # simulating the hard-delete job cascades dependent: :destroy
        expect {
          Flashcard.unscoped.find(flashcard.id).destroy
        }.to change(LearnSessionItem, :count).by(-1)
      end

      it "stays on the same page when cards remain on that page" do
        # 11 cards → page 2 has 1 card; deleting it leaves 10 cards still on page 1
        # Use 11 cards with items=10: page 2 has 1 card
        create_list(:flashcard, 10, deck: deck)
        card_on_page_2 = flashcard

        delete flashcard_path(card_on_page_2), params: { page: 2, items: 10 }

        # 10 cards remain, last valid page is 1, so safe_page clamps to 1
        expect(response).to redirect_to(deck_path(deck, page: 1, items: 10))
      end

      it "falls back to the previous page when deleting the only card on the last page" do
        # 11 cards, items=10: page 2 has 1 card; after deleting, only page 1 exists
        create_list(:flashcard, 10, deck: deck)
        last_card = flashcard

        delete flashcard_path(last_card), params: { page: 2, items: 10 }

        expect(response).to redirect_to(deck_path(deck, page: 1, items: 10))
      end

      it "stays on page 2 when other cards remain on page 2" do
        # 12 cards, items=5: page 2 has cards 6-10; deleting one leaves 11 cards (page 2 still valid)
        create_list(:flashcard, 11, deck: deck)
        card_to_delete = flashcard  # 12th card

        delete flashcard_path(card_to_delete), params: { page: 2, items: 5 }

        # 11 cards remain, last_page = ceil(11/5) = 3, safe_page = min(2,3) = 2
        expect(response).to redirect_to(deck_path(deck, page: 2, items: 5))
      end
    end

    context "when requested with turbo stream format" do
      before { sign_in(user) }

      it "removes the flashcard and renders turbo stream" do
        flashcard
        expect {
          delete flashcard_path(flashcard),
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(Flashcard, :count).by(-1)
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("deck_#{deck.id}_card_count")
      end

      it "reflects the correct count after multiple sequential deletes" do
        card_a = create(:flashcard, deck: deck)
        card_b = create(:flashcard, deck: deck)

        delete flashcard_path(card_a), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include(">#{deck.reload.flashcards_count}<")

        delete flashcard_path(card_b), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include(">#{deck.reload.flashcards_count}<")

        expect(deck.reload.flashcards_count).to eq(0)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects away" do
        delete flashcard_path(flashcard)
        expect(response).to redirect_to(decks_path)
      end

      it "does not destroy the flashcard" do
        flashcard
        expect {
          delete flashcard_path(flashcard)
        }.not_to change(Flashcard, :count)
      end
    end

    context "when authenticated as another user on a people_with_password deck (not unlocked)" do
      let(:owner)   { create(:user) }
      let(:pw_deck) { create(:deck, :editable_by_password, user: owner) }
      let(:pw_card) { create(:flashcard, deck: pw_deck) }
      let(:other)   { create(:user) }
      before { sign_in(other) }

      it "redirects to the unlock page" do
        pw_card
        delete flashcard_path(pw_card)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "does not destroy the flashcard" do
        pw_card
        expect {
          delete flashcard_path(pw_card)
        }.not_to change(Flashcard, :count)
      end
    end

    context "when authenticated as a password user (content domain)" do
      let(:owner)   { create(:user) }
      let(:pw_deck) { create(:deck, :editable_by_password, user: owner) }
      let(:pw_card) { create(:flashcard, deck: pw_deck) }
      let(:other)   { create(:user) }
      before do
        sign_in(other)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
      end

      it "soft-deletes the flashcard" do
        pw_card
        expect {
          delete flashcard_path(pw_card)
        }.to change(Flashcard, :count).by(-1)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete flashcard_path(flashcard)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
