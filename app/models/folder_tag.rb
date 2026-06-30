class FolderTag < ApplicationRecord
  # Palette used for the colored dot shown next to each tag. A color is assigned
  # on creation by cycling through the palette so tags in a folder look distinct.
  COLORS = %w[#7c5cff #3b82f6 #22c55e #f59e0b #ec4899 #14b8a6 #ef4444 #06b6d4].freeze

  belongs_to :folder
  has_many :deck_folder_tags, dependent: :destroy
  has_many :decks, through: :deck_folder_tags

  validates :name, presence: true,
                   length: { maximum: 60 },
                   uniqueness: { scope: :folder_id, case_sensitive: false }

  before_create :assign_color

  private

  def assign_color
    return if color.present?

    self.color = COLORS[folder.folder_tags.count % COLORS.size]
  end
end
