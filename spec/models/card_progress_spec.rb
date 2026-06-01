require "rails_helper"

RSpec.describe CardProgress, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      cp = build(:card_progress)
      expect(cp).to be_valid
    end

    it "is invalid when ease_factor < 1.3" do
      cp = build(:card_progress, ease_factor: 1.2)
      expect(cp).not_to be_valid
    end

    it "is invalid when interval < 1" do
      cp = build(:card_progress, interval: 0)
      expect(cp).not_to be_valid
    end

    it "is invalid when repetitions < 0" do
      cp = build(:card_progress, repetitions: -1)
      expect(cp).not_to be_valid
    end

    it "enforces uniqueness of flashcard_id scoped to user_id" do
      existing = create(:card_progress)
      duplicate = build(:card_progress, user: existing.user, flashcard: existing.flashcard)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".due scope" do
    let(:user) { create(:user) }

    it "returns records where next_review_at <= now" do
      due_cp = create(:card_progress, :due, user: user)
      expect(CardProgress.due).to include(due_cp)
    end

    it "excludes records with next_review_at in the future" do
      future_cp = create(:card_progress, :future, user: user)
      expect(CardProgress.due).not_to include(future_cp)
    end

    it "orders by oldest next_review_at first" do
      newer = create(:card_progress, user: user, next_review_at: 1.hour.ago)
      older = create(:card_progress, user: user, next_review_at: 2.days.ago)
      expect(CardProgress.due.first).to eq(older)
    end
  end

  describe ".initialize_for_deck" do
    let(:user)  { create(:user) }
    let(:deck)  { create(:deck, user: user) }

    it "creates CardProgress records for all new flashcards" do
      flashcard = create(:flashcard, deck: deck)
      expect {
        CardProgress.initialize_for_deck(deck, user)
      }.to change(CardProgress, :count).by(1)

      cp = CardProgress.find_by(user: user, flashcard: flashcard)
      expect(cp).to be_present
      expect(cp.next_review_at).to be_within(5.seconds).of(Time.current)
    end

    it "sets default SM-2 values" do
      create(:flashcard, deck: deck)
      CardProgress.initialize_for_deck(deck, user)
      cp = CardProgress.last
      expect(cp.ease_factor).to eq(2.5)
      expect(cp.interval).to eq(1)
      expect(cp.repetitions).to eq(0)
    end

    it "is idempotent — does not create duplicates on second call" do
      create(:flashcard, deck: deck)
      CardProgress.initialize_for_deck(deck, user)
      expect {
        CardProgress.initialize_for_deck(deck, user)
      }.not_to change(CardProgress, :count)
    end

    it "does not touch existing card_progresses" do
      flashcard = create(:flashcard, deck: deck)
      existing  = create(:card_progress, user: user, flashcard: flashcard,
                          ease_factor: 1.8, repetitions: 3)
      CardProgress.initialize_for_deck(deck, user)
      expect(existing.reload.ease_factor).to eq(1.8)
    end
  end
end
