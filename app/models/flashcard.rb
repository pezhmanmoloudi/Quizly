class Flashcard < ApplicationRecord
  belongs_to :deck
  has_many :card_progresses,     dependent: :destroy
  has_many :learn_session_items, dependent: :destroy

  validates :front_content, presence: true
  validates :back_content, presence: true

  default_scope { order(:position, :id) }
end
