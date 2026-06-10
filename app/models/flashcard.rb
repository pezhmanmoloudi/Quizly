class Flashcard < ApplicationRecord
  belongs_to :deck, counter_cache: :flashcards_count
  has_many :card_progresses,     dependent: :destroy
  has_many :learn_session_items, dependent: :destroy
  has_one_attached :image

  validates :front_content, presence: true
  validates :back_content, presence: true

  default_scope { where(deleted_at: nil).order(:position, :id) }

  def soft_delete!
    ActiveRecord::Base.transaction do
      update_columns(deleted_at: Time.current)
      Deck.decrement_counter(:flashcards_count, deck_id)
    end
  end

  def restore!
    ActiveRecord::Base.transaction do
      update_columns(deleted_at: nil)
      Deck.increment_counter(:flashcards_count, deck_id)
    end
  end
end
