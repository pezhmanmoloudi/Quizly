class CardProgress < ApplicationRecord
  belongs_to :user
  belongs_to :flashcard

  validates :ease_factor, numericality: { greater_than_or_equal_to: 1.3 }
  validates :interval, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :repetitions, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :flashcard_id, uniqueness: { scope: :user_id }

  scope :due,     -> { where("next_review_at <= ?", Time.current).order(:next_review_at) }
  scope :starred, -> { where(starred: true) }

  def self.initialize_for_deck(deck, user)
    existing_ids = where(user: user, flashcard: deck.flashcards).pluck(:flashcard_id)
    new_ids = deck.flashcard_ids - existing_ids
    return if new_ids.empty?

    now = Time.current
    inserts = new_ids.map do |fid|
      { user_id: user.id, flashcard_id: fid,
        ease_factor: 2.5, interval: 1, repetitions: 0,
        next_review_at: now, last_reviewed_at: nil,
        created_at: now, updated_at: now }
    end
    insert_all(inserts)
  end
end
