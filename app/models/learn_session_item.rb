class LearnSessionItem < ApplicationRecord
  STATUSES = %w[unseen learning mastered].freeze

  belongs_to :learn_session
  belongs_to :flashcard

  validates :status, inclusion: { in: STATUSES }
  validates :position, presence: true
  validates :flashcard_id, uniqueness: { scope: :learn_session_id }

  def mastered? = status == "mastered"

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
