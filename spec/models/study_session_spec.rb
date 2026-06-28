require "rails_helper"

RSpec.describe StudySession, type: :model do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "validations" do
    it "is valid with valid attributes" do
      session = build(:study_session, user: user, deck: deck)
      expect(session).to be_valid
    end

    it "is invalid without started_at" do
      session = build(:study_session, user: user, deck: deck, started_at: nil)
      expect(session).not_to be_valid
    end

    it "is invalid when cards_total is negative" do
      session = build(:study_session, user: user, deck: deck, cards_total: -1)
      expect(session).not_to be_valid
    end

    it "is invalid when cards_reviewed is negative" do
      session = build(:study_session, user: user, deck: deck, cards_reviewed: -1)
      expect(session).not_to be_valid
    end

    it "is invalid when cards_correct is negative" do
      session = build(:study_session, user: user, deck: deck, cards_correct: -1)
      expect(session).not_to be_valid
    end

    it "is valid with all counts at zero" do
      session = build(:study_session, user: user, deck: deck,
                      cards_total: 0, cards_reviewed: 0, cards_correct: 0)
      expect(session).to be_valid
    end
  end

  describe "scopes" do
    describe ".completed" do
      it "includes sessions with a finished_at timestamp" do
        completed = create(:study_session, :completed, user: user, deck: deck)
        expect(described_class.completed).to include(completed)
      end

      it "excludes sessions without a finished_at timestamp" do
        ongoing = create(:study_session, user: user, deck: deck, finished_at: nil)
        expect(described_class.completed).not_to include(ongoing)
      end
    end

    describe ".recent" do
      it "orders sessions by started_at descending" do
        older = create(:study_session, user: user, deck: deck, started_at: 2.days.ago)
        newer = create(:study_session, user: user, deck: deck, started_at: 1.hour.ago)
        ordered = described_class.recent.to_a
        expect(ordered.index(newer)).to be < ordered.index(older)
      end
    end
  end

  describe "#finished?" do
    it "returns false when finished_at is nil" do
      session = build(:study_session, user: user, deck: deck, finished_at: nil)
      expect(session.finished?).to be false
    end

    it "returns true when finished_at is set" do
      session = build(:study_session, :completed, user: user, deck: deck)
      expect(session.finished?).to be true
    end
  end

  describe "#accuracy" do
    it "returns 0 when no cards have been reviewed" do
      session = build(:study_session, user: user, deck: deck,
                      cards_reviewed: 0, cards_correct: 0)
      expect(session.accuracy).to eq(0)
    end

    it "calculates percentage correctly" do
      session = build(:study_session, user: user, deck: deck,
                      cards_reviewed: 10, cards_correct: 8)
      expect(session.accuracy).to eq(80)
    end

    it "rounds to nearest integer" do
      session = build(:study_session, user: user, deck: deck,
                      cards_reviewed: 3, cards_correct: 1)
      expect(session.accuracy).to eq(33)
    end

    it "returns 100 when all cards are correct" do
      session = build(:study_session, user: user, deck: deck,
                      cards_reviewed: 5, cards_correct: 5)
      expect(session.accuracy).to eq(100)
    end
  end

  describe "#elapsed_seconds" do
    it "uses finished_at when present" do
      started  = 10.minutes.ago
      finished = 5.minutes.ago
      session  = build(:study_session, user: user, deck: deck,
                        started_at: started, finished_at: finished)
      expect(session.elapsed_seconds).to be_within(2).of(300)
    end

    it "uses Time.current when finished_at is nil" do
      session = build(:study_session, user: user, deck: deck,
                      started_at: 30.seconds.ago, finished_at: nil)
      expect(session.elapsed_seconds).to be_within(5).of(30)
    end
  end
end
