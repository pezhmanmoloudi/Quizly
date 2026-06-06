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
    it "builds a session with items for every deck card" do
      user = create(:user)
      deck = create(:deck, user: user)
      3.times { create(:flashcard, deck: deck) }
      ls = LearnSession.build_for(deck: deck, user: user)
      ls.save!
      expect(ls.learn_session_items.count).to eq 3
      expect(ls.cards_total).to eq 3
    end
  end
end
