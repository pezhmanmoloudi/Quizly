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

  describe "#record_feedback!" do
    let(:item) { build_item(status: "unseen", attempts: 0, mastery_score: 0, confusion_count: 0, position: 0) }

    context "got_it" do
      it "increments attempts" do
        item.record_feedback!("got_it")
        expect(item.attempts).to eq 1
      end

      it "adds 20 to mastery_score" do
        item.record_feedback!("got_it")
        expect(item.mastery_score).to eq 20
      end

      it "clamps mastery_score at 100" do
        item.update!(mastery_score: 90)
        item.record_feedback!("got_it")
        expect(item.mastery_score).to eq 100
      end

      it "sets status to learning when mastery_score < 70" do
        item.record_feedback!("got_it")
        expect(item.status).to eq "learning"
      end

      it "sets status to mastered when mastery_score reaches 70" do
        item.update!(mastery_score: 50)
        item.record_feedback!("got_it")
        expect(item.mastery_score).to eq 70
        expect(item.status).to eq "mastered"
      end

      it "does not re-queue a newly mastered card" do
        item.update!(mastery_score: 50)
        original_position = item.position
        item.record_feedback!("got_it")
        expect(item.position).to eq original_position
      end

      it "sets last_seen_at to current time" do
        freeze_time do
          item.record_feedback!("got_it")
          expect(item.last_seen_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context "confused" do
      it "subtracts 10 from mastery_score" do
        item.update!(mastery_score: 50)
        item.record_feedback!("confused")
        expect(item.mastery_score).to eq 40
      end

      it "clamps mastery_score at 0" do
        item.update!(mastery_score: 5)
        item.record_feedback!("confused")
        expect(item.mastery_score).to eq 0
      end

      it "increments confusion_count" do
        item.record_feedback!("confused")
        expect(item.confusion_count).to eq 1
      end

      it "sets status to learning" do
        item.record_feedback!("confused")
        expect(item.status).to eq "learning"
      end

      it "moves card to end of queue" do
        other = create(:learn_session_item,
                       learn_session: learn_session,
                       flashcard: create(:flashcard, deck: deck),
                       position: 5)
        item.record_feedback!("confused")
        expect(item.position).to be > other.position
      end
    end

    context "dont_know" do
      it "subtracts 25 from mastery_score" do
        item.update!(mastery_score: 50)
        item.record_feedback!("dont_know")
        expect(item.mastery_score).to eq 25
      end

      it "clamps mastery_score at 0" do
        item.update!(mastery_score: 10)
        item.record_feedback!("dont_know")
        expect(item.mastery_score).to eq 0
      end

      it "increments attempts" do
        item.record_feedback!("dont_know")
        expect(item.attempts).to eq 1
      end

      it "sets status to learning" do
        item.record_feedback!("dont_know")
        expect(item.status).to eq "learning"
      end

      it "moves card to end of queue" do
        other = create(:learn_session_item,
                       learn_session: learn_session,
                       flashcard: create(:flashcard, deck: deck),
                       position: 5)
        item.record_feedback!("dont_know")
        expect(item.position).to be > other.position
      end
    end

    context "with configurable mastery_threshold" do
      it "marks mastered when score reaches the given threshold (80)" do
        item.update!(mastery_score: 60)
        item.record_feedback!("got_it", mastery_threshold: 80)
        expect(item.mastery_score).to eq 80
        expect(item.status).to eq "mastered"
      end

      it "keeps status learning when score is below the given threshold (90)" do
        item.update!(mastery_score: 60)
        item.record_feedback!("got_it", mastery_threshold: 90)
        expect(item.mastery_score).to eq 80
        expect(item.status).to eq "learning"
      end

      it "uses MASTERY_THRESHOLD (70) as default when no keyword given" do
        item.update!(mastery_score: 50)
        item.record_feedback!("got_it")
        expect(item.mastery_score).to eq 70
        expect(item.status).to eq "mastered"
      end
    end
  end
end
