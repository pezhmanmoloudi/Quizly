class DeckFolder < ApplicationRecord
  belongs_to :deck
  belongs_to :folder

  validates :deck_id, uniqueness: { scope: :folder_id }
end
