class LearnSession < ApplicationRecord
  MASTERY_THRESHOLD = 1

  belongs_to :user
  belongs_to :deck
  has_many :learn_session_items, dependent: :destroy

  validates :started_at, presence: true
  validates :cards_total, :cards_mastered,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active,  -> { where(finished_at: nil) }
  scope :completed, -> { where.not(finished_at: nil) }
  scope :recent,  -> { order(started_at: :desc) }

  def finished? = finished_at.present?
  def completion_pct = cards_total.zero? ? 0 : (cards_mastered.to_f / cards_total * 100).round
  def elapsed_seconds = ((finished_at || Time.current) - started_at).to_i

  def next_item
    learn_session_items
      .joins(:flashcard)
      .includes(:flashcard)
      .where.not(status: "mastered")
      .order(Arel.sql("CASE learn_session_items.status WHEN 'unseen' THEN 0 ELSE 1 END, learn_session_items.position"))
      .first
  end

  def self.build_for(deck:, user:)
    cards = deck.flashcards.to_a.shuffle
    session = new(user: user, deck: deck, cards_total: cards.size, started_at: Time.current)
    cards.each_with_index do |card, i|
      session.learn_session_items.build(flashcard: card, position: i)
    end
    session
  end
end
