class Folder < ApplicationRecord
  belongs_to :user
  has_many :deck_folders, dependent: :destroy
  has_many :decks, through: :deck_folders
  has_many :folder_tags, dependent: :destroy

  KIND_VALUES = %w[manual smart ai_generated system].freeze

  validates :name, presence: true, length: { maximum: 60 }
  validates :kind, inclusion: { in: KIND_VALUES }
end
