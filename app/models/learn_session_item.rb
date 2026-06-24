class LearnSessionItem < ApplicationRecord
  STATUSES          = %w[unseen learning mastered].freeze
  MASTERY_THRESHOLD = 70
  WEAK_THRESHOLD    = 40

  FEEDBACK_DELTAS = {
    "got_it"    => +20,
    "confused"  => -10,
    "dont_know" => -25
  }.freeze

  belongs_to :learn_session
  belongs_to :flashcard

  validates :status, inclusion: { in: STATUSES }
  validates :position, presence: true
  validates :flashcard_id, uniqueness: { scope: :learn_session_id }

  def mastered? = status == "mastered"

  def record_feedback!(feedback, mastery_threshold: MASTERY_THRESHOLD)
    delta              = FEEDBACK_DELTAS.fetch(feedback, 0)
    self.mastery_score   = (mastery_score + delta).clamp(0, 100)
    self.confusion_count += 1 if feedback == "confused"
    self.attempts       += 1
    self.last_seen_at   = Time.current
    self.status = mastery_score >= mastery_threshold ? "mastered" : "learning"

    unless mastered?
      max_pos       = learn_session.learn_session_items.maximum(:position) || 0
      self.position = max_pos + 1
    end

    save!
  end

  def record_correct!
    self.attempts += 1
    self.correct_streak += 1
    self.status = correct_streak >= LearnSession::MASTERY_THRESHOLD ? "mastered" : "learning"
    save!
  end

  def record_incorrect!
    self.attempts += 1
    self.correct_streak = 0
    self.status = "learning"
    max_pos = learn_session.learn_session_items.maximum(:position) || 0
    self.position = max_pos + 1
    save!
  end
end
