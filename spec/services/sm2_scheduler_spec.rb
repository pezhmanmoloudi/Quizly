require "rails_helper"

RSpec.describe Sm2Scheduler, type: :service do
  def build_progress(attrs = {})
    create(:card_progress, { ease_factor: 2.5, interval: 1, repetitions: 0 }.merge(attrs))
  end

  describe ".grade_card" do
    context "first review, quality 4 (Good)" do
      it "sets interval to 1" do
        cp = build_progress(repetitions: 0)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.interval).to eq(1)
      end

      it "increments repetitions to 1" do
        cp = build_progress(repetitions: 0)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.repetitions).to eq(1)
      end

      it "adjusts ease_factor (quality 4 → ~2.5)" do
        cp = build_progress(ease_factor: 2.5, repetitions: 0)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.ease_factor).to be_within(0.01).of(2.5)
      end
    end

    context "second review, quality 4 (Good)" do
      it "sets interval to 6" do
        cp = build_progress(repetitions: 1, interval: 1)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.interval).to eq(6)
      end

      it "increments repetitions to 2" do
        cp = build_progress(repetitions: 1)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.repetitions).to eq(2)
      end
    end

    context "third review, quality 4 (repetitions: 2, interval: 6, ease_factor: 2.5)" do
      it "sets interval to (6 * 2.5).round = 15" do
        cp = build_progress(repetitions: 2, interval: 6, ease_factor: 2.5)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.interval).to eq(15)
      end

      it "increments repetitions to 3" do
        cp = build_progress(repetitions: 2, interval: 6, ease_factor: 2.5)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.repetitions).to eq(3)
      end
    end

    context "quality 5 (Easy)" do
      it "increases ease_factor above 2.5" do
        cp = build_progress(ease_factor: 2.5, repetitions: 1)
        Sm2Scheduler.grade_card(cp, 5)
        expect(cp.reload.ease_factor).to be > 2.5
      end
    end

    context "quality 3 (Hard)" do
      it "decreases ease_factor below 2.5" do
        cp = build_progress(ease_factor: 2.5, repetitions: 1)
        Sm2Scheduler.grade_card(cp, 3)
        expect(cp.reload.ease_factor).to be < 2.5
      end
    end

    context "ease_factor minimum clamp" do
      it "never drops below 1.3 regardless of repeated failures" do
        cp = build_progress(ease_factor: 1.3, repetitions: 2, interval: 6)
        Sm2Scheduler.grade_card(cp, 3)
        expect(cp.reload.ease_factor).to be >= Sm2Scheduler::MIN_EASE_FACTOR
      end
    end

    context "quality 1 (Again — failed recall)" do
      it "resets repetitions to 0" do
        cp = build_progress(repetitions: 3, interval: 15)
        Sm2Scheduler.grade_card(cp, 1)
        expect(cp.reload.repetitions).to eq(0)
      end

      it "resets interval to 1" do
        cp = build_progress(repetitions: 3, interval: 15)
        Sm2Scheduler.grade_card(cp, 1)
        expect(cp.reload.interval).to eq(1)
      end

      it "does not change ease_factor" do
        cp = build_progress(ease_factor: 2.3, repetitions: 3)
        original_ef = cp.ease_factor
        Sm2Scheduler.grade_card(cp, 1)
        expect(cp.reload.ease_factor).to eq(original_ef)
      end

      it "schedules next_review_at approximately 1 day from now" do
        cp = build_progress
        Sm2Scheduler.grade_card(cp, 1)
        expect(cp.reload.next_review_at).to be_within(5.seconds).of(1.day.from_now)
      end
    end

    context "quality 0 (worst failure)" do
      it "resets repetitions and interval" do
        cp = build_progress(repetitions: 5, interval: 30)
        Sm2Scheduler.grade_card(cp, 0)
        expect(cp.reload.repetitions).to eq(0)
        expect(cp.reload.interval).to eq(1)
      end
    end

    context "persistence" do
      it "saves the record" do
        cp = build_progress
        expect { Sm2Scheduler.grade_card(cp, 4) }.not_to raise_error
        expect(cp).to be_persisted
      end

      it "updates last_reviewed_at to approximately now" do
        cp = build_progress
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.last_reviewed_at).to be_within(5.seconds).of(Time.current)
      end

      it "sets next_review_at for quality >= 3 to interval days from now" do
        cp = build_progress(repetitions: 1, interval: 1)
        Sm2Scheduler.grade_card(cp, 4)
        expect(cp.reload.next_review_at).to be_within(5.seconds).of(6.days.from_now)
      end
    end
  end
end
