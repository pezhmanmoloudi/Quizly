class TestSession < ApplicationRecord
  belongs_to :user
  belongs_to :deck

  validates :started_at, presence: true
  validates :questions_total, :score, :current_index,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :completed, -> { where.not(finished_at: nil) }
  scope :recent,    -> { order(started_at: :desc) }

  def finished? = finished_at.present?
  def accuracy  = questions_total.zero? ? 0 : (score.to_f / questions_total * 100).round
  def elapsed_seconds = ((finished_at || Time.current) - started_at).to_i
  def questions = JSON.parse(questions_data)
  def current_question = questions[current_index]
  def last_question? = current_index >= questions_total - 1
end
