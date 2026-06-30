class DeckFolderTag < ApplicationRecord
  belongs_to :folder_tag
  belongs_to :deck

  validates :deck_id, uniqueness: { scope: :folder_tag_id }
end
