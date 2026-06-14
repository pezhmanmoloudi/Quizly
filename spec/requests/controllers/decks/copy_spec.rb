require "rails_helper"

RSpec.describe "Decks#copy", type: :request do
  let(:owner)  { create(:user) }
  let(:copier) { create(:user) }

  let(:public_deck) do
    deck = create(:deck, user: owner, visibility: "public", name: "French Basics")
    create(:flashcard, deck:, front_content: "bonjour", back_content: "hello", position: 1)
    create(:flashcard, deck:, front_content: "merci",   back_content: "thank you", position: 2)
    deck
  end

  let(:unlisted_deck) { create(:deck, :unlisted, user: owner, name: "Unlisted Deck") }
  let(:private_deck)  { create(:deck, :private,  user: owner, name: "Private Deck") }
  let(:empty_deck)    { create(:deck, :public,   user: owner, name: "Empty Deck") }

  describe "POST /decks/:id/copy" do
    # ── non-owner copies a public deck ────────────────────────────────────────

    context "when authenticated as a non-owner (public deck)" do
      before { sign_in(copier) }

      it "creates a new Deck owned by the copier" do
        expect {
          post copy_deck_path(public_deck)
        }.to change { copier.decks.count }.by(1)
      end

      it "does not modify or destroy the original deck" do
        original_name = public_deck.name
        post copy_deck_path(public_deck)
        expect(public_deck.reload.name).to eq(original_name)
      end

      it "deep-copies all flashcards as new records" do
        public_deck
        expect {
          post copy_deck_path(public_deck)
        }.to change { Flashcard.count }.by(2)
      end

      it "copies flashcard content correctly" do
        post copy_deck_path(public_deck)
        copied = copier.decks.last
        expect(copied.flashcards.order(:position).map(&:front_content)).to eq(%w[bonjour merci])
      end

      it "copied flashcards have different IDs from the originals" do
        original_ids = public_deck.flashcard_ids
        post copy_deck_path(public_deck)
        copied_ids = copier.decks.last.flashcard_ids
        expect(copied_ids).not_to include(*original_ids)
      end

      it "sets source_deck on the copy" do
        post copy_deck_path(public_deck)
        expect(copier.decks.last.source_deck).to eq(public_deck)
      end

      it "sets the copied deck's visibility to private" do
        post copy_deck_path(public_deck)
        expect(copier.decks.last.visibility).to eq("private")
      end

      it "appends (Copy) to the name" do
        post copy_deck_path(public_deck)
        expect(copier.decks.last.name).to eq("French Basics (Copy)")
      end

      it "redirects to the new deck's show page" do
        post copy_deck_path(public_deck)
        copied = copier.decks.last
        expect(response).to redirect_to(deck_path(copied))
      end

      it "shows the copy-created flash notice after redirect" do
        post copy_deck_path(public_deck)
        follow_redirect!
        expect(response.body).to include("Copy created")
      end
    end

    # ── empty deck ────────────────────────────────────────────────────────────

    context "when the deck has no flashcards" do
      before { sign_in(copier) }

      it "succeeds and creates a deck with 0 flashcards" do
        post copy_deck_path(empty_deck)
        expect(copier.decks.last.flashcards.count).to eq(0)
      end

      it "redirects to the new deck" do
        post copy_deck_path(empty_deck)
        expect(response).to redirect_to(deck_path(copier.decks.last))
      end
    end

    # ── unlisted deck ─────────────────────────────────────────────────────────

    context "when copying an unlisted deck" do
      before { sign_in(copier) }

      it "creates a new deck for the copier" do
        expect {
          post copy_deck_path(unlisted_deck)
        }.to change { copier.decks.count }.by(1)
      end

      it "redirects to the copied deck" do
        post copy_deck_path(unlisted_deck)
        expect(response).to redirect_to(deck_path(copier.decks.last))
      end
    end

    # ── private deck ──────────────────────────────────────────────────────────

    context "when the deck is private" do
      before { sign_in(copier) }

      it "does not create a new deck" do
        private_deck
        expect {
          post copy_deck_path(private_deck)
        }.not_to change { Deck.count }
      end

      it "returns a 404 redirect (set_accessible_deck blocks before action runs)" do
        post copy_deck_path(private_deck)
        expect(response).to redirect_to(decks_path)
      end
    end

    # ── owner behavior ────────────────────────────────────────────────────────

    context "when authenticated as the deck owner" do
      before { sign_in(owner) }

      it "does not create a copy" do
        public_deck
        expect {
          post copy_deck_path(public_deck)
        }.not_to change { Deck.count }
      end

      it "redirects to explore" do
        post copy_deck_path(public_deck)
        expect(response).to redirect_to(explore_path)
      end
    end

    # ── unauthenticated ───────────────────────────────────────────────────────

    context "when not authenticated" do
      it "redirects to login" do
        post copy_deck_path(public_deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
