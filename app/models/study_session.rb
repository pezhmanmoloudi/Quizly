class StudySession < ApplicationRecord
  belongs_to :user
  belongs_to :deck

  validates :started_at, presence: true
  validates :cards_total, :cards_reviewed, :cards_correct,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :completed, -> { where.not(finished_at: nil) }
  scope :recent,    -> { order(started_at: :desc) }

  def finished? = finished_at.present?
  def accuracy  = cards_reviewed.zero? ? 0 : (cards_correct.to_f / cards_reviewed * 100).round
  def elapsed_seconds = ((finished_at || Time.current) - started_at).to_i
end
