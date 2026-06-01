class Deck < ApplicationRecord
  belongs_to :user
  has_many :flashcards, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
end
