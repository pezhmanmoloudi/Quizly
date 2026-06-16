class Folder < ApplicationRecord
  belongs_to :user
  has_many :deck_folders, dependent: :destroy
  has_many :decks, through: :deck_folders

  validates :name, presence: true, length: { maximum: 100 }
end
