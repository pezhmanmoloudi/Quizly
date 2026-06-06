require "rails_helper"

RSpec.describe LearnSessionItem, type: :model do
  let(:learn_session) { create(:learn_session) }
  let(:deck) { learn_session.deck }

  def build_item(attrs = {})
    create(:learn_session_item,
           learn_session: learn_session,
           flashcard: create(:flashcard, deck: deck),
           **attrs)
  end

  describe "validations" do
    it "is valid with valid attributes" do
      item = build_item(status: "unseen", position: 0)
      expect(item).to be_valid
    end

    it "is invalid with unknown status" do
      item = build(:learn_session_item,
                   learn_session: learn_session,
                   flashcard: create(:flashcard, deck: deck),
                   status: "bogus")
      expect(item).not_to be_valid
    end

    it "is invalid without position" do
      item = build(:learn_session_item,
                   learn_session: learn_session,
                   flashcard: create(:flashcard, deck: deck))
      item.position = nil
      expect(item).not_to be_valid
    end
  end

  describe "#record_correct!" do
    let(:item) { build_item(status: "unseen", attempts: 0, correct_streak: 0, position: 0) }

    it "increments attempts and correct_streak" do
      item.record_correct!
      expect(item.attempts).to eq 1
      expect(item.correct_streak).to eq 1
    end

    it "marks as mastered when streak reaches MASTERY_THRESHOLD" do
      item.record_correct!
      expect(item.status).to eq "mastered"
    end
  end

  describe "#record_incorrect!" do
    let(:item) { build_item(status: "unseen", attempts: 0, correct_streak: 0, position: 0) }

    it "increments attempts and resets correct_streak to 0" do
      item.record_incorrect!
      expect(item.attempts).to eq 1
      expect(item.correct_streak).to eq 0
    end

    it "sets status to learning" do
      item.record_incorrect!
      expect(item.status).to eq "learning"
    end

    it "moves card to end of queue" do
      other = create(:learn_session_item,
                     learn_session: learn_session,
                     flashcard: create(:flashcard, deck: deck),
                     position: 5)
      item.record_incorrect!
      expect(item.position).to be > other.position
    end
  end
end
