class Deck < ApplicationRecord
  belongs_to :user
  belongs_to :forked_from, class_name: "Deck", optional: true
  has_many :forks, class_name: "Deck", foreign_key: :forked_from_id, dependent: :nullify
  has_many :flashcards, dependent: :destroy

  scope :public_decks, -> { where(visibility: "public") }
  scope :popular, -> { order(forks_count: :desc, created_at: :desc) }

  validates :name, presence: true, length: { maximum: 100 }
  validates :visibility, inclusion: { in: %w[private public] }

  def public? = visibility == "public"
  def private? = visibility == "private"

  def tag_list
    return [] if subject_tags.blank?
    subject_tags.split(",").map(&:strip).reject(&:blank?)
  end

  def tag_list=(tags_string)
    self.subject_tags = tags_string.to_s.split(",").map(&:strip).reject(&:blank?).join(", ")
  end
end
