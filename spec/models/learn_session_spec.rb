require "rails_helper"

RSpec.describe LearnSession, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      ls = build(:learn_session)
      expect(ls).to be_valid
    end

    it "is invalid without started_at" do
      ls = build(:learn_session, started_at: nil)
      expect(ls).not_to be_valid
    end

    it "is invalid when cards_total is negative" do
      ls = build(:learn_session, cards_total: -1)
      expect(ls).not_to be_valid
    end
  end

  describe "#completion_pct" do
    it "returns 0 when no cards" do
      ls = build(:learn_session, cards_total: 0, cards_mastered: 0)
      expect(ls.completion_pct).to eq 0
    end

    it "returns rounded percentage" do
      ls = build(:learn_session, cards_total: 3, cards_mastered: 1)
      expect(ls.completion_pct).to eq 33
    end

    it "returns 100 when all mastered" do
      ls = build(:learn_session, cards_total: 3, cards_mastered: 3)
      expect(ls.completion_pct).to eq 100
    end
  end

  describe "#next_item" do
    let(:learn_session) { create(:learn_session) }
    let(:deck) { learn_session.deck }

    it "returns the item with lowest position" do
      card_a = create(:flashcard, deck: deck)
      card_b = create(:flashcard, deck: deck)
      item_a = create(:learn_session_item, learn_session: learn_session, flashcard: card_a, position: 1)
      item_b = create(:learn_session_item, learn_session: learn_session, flashcard: card_b, position: 0)
      expect(learn_session.next_item).to eq item_b
    end

    it "returns nil when all items are mastered" do
      card = create(:flashcard, deck: deck)
      create(:learn_session_item, learn_session: learn_session, flashcard: card,
             status: "mastered", position: 0)
      expect(learn_session.next_item).to be_nil
    end

    it "skips items whose flashcard has been soft-deleted" do
      live_card    = create(:flashcard, deck: deck)
      deleted_card = create(:flashcard, deck: deck)
      create(:learn_session_item, learn_session: learn_session, flashcard: deleted_card, position: 0)
      live_item = create(:learn_session_item, learn_session: learn_session, flashcard: live_card, position: 1)
      deleted_card.soft_delete!
      expect(learn_session.next_item).to eq live_item
    end

    it "prioritises unseen over learning items" do
      card_a = create(:flashcard, deck: deck)
      card_b = create(:flashcard, deck: deck)
      learning = create(:learn_session_item, learn_session: learn_session,
                        flashcard: card_a, status: "learning", position: 0)
      unseen  = create(:learn_session_item, learn_session: learn_session,
                       flashcard: card_b, status: "unseen", position: 1)
      expect(learn_session.next_item).to eq unseen
    end
  end

  describe ".build_for" do
    let(:user) { create(:user) }
    let(:deck) { create(:deck, user: user) }

    it "builds a session with items for every deck card" do
      3.times { create(:flashcard, deck: deck) }
      ls = LearnSession.build_for(deck: deck, user: user)
      ls.save!
      expect(ls.learn_session_items.count).to eq 3
      expect(ls.cards_total).to eq 3
    end

    context "with flashcard_ids filter" do
      it "creates items only for the specified flashcards" do
        fc1 = create(:flashcard, deck: deck)
        fc2 = create(:flashcard, deck: deck)
        ls  = LearnSession.build_for(deck: deck, user: user, flashcard_ids: [fc1.id])
        ls.save!
        expect(ls.learn_session_items.pluck(:flashcard_id)).to eq [fc1.id]
        expect(ls.cards_total).to eq 1
      end

      it "ignores IDs not belonging to the deck" do
        fc1   = create(:flashcard, deck: deck)
        other = create(:flashcard, deck: create(:deck, user: user))
        ls    = LearnSession.build_for(deck: deck, user: user, flashcard_ids: [fc1.id, other.id])
        ls.save!
        expect(ls.learn_session_items.pluck(:flashcard_id)).to eq [fc1.id]
      end
    end

    context "with a session-size limit (backend owns membership)" do
      before { 6.times { create(:flashcard, deck: deck) } }

      it "caps session items to the limit when the deck has more cards" do
        ls = LearnSession.build_for(deck: deck, user: user, limit: 4)
        ls.save!
        expect(ls.learn_session_items.count).to eq 4
        expect(ls.cards_total).to eq 4
      end

      it "keeps all cards when the limit exceeds the deck size" do
        ls = LearnSession.build_for(deck: deck, user: user, limit: 20)
        ls.save!
        expect(ls.learn_session_items.count).to eq 6
      end

      it "treats limit 0 as unlimited (all cards)" do
        ls = LearnSession.build_for(deck: deck, user: user, limit: 0)
        ls.save!
        expect(ls.learn_session_items.count).to eq 6
      end

      it "treats nil limit as unlimited (all cards)" do
        ls = LearnSession.build_for(deck: deck, user: user, limit: nil)
        ls.save!
        expect(ls.learn_session_items.count).to eq 6
      end

      it "does not apply the limit on the weak-only retry path" do
        ids = deck.flashcards.limit(5).pluck(:id)
        ls  = LearnSession.build_for(deck: deck, user: user, flashcard_ids: ids, limit: 2)
        ls.save!
        expect(ls.learn_session_items.count).to eq 5
      end
    end
  end
end
