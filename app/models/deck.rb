class Deck < ApplicationRecord
  belongs_to :user
  belongs_to :forked_from, class_name: "Deck", optional: true
  has_many :forks, class_name: "Deck", foreign_key: :forked_from_id, dependent: :nullify
  has_many :flashcards, dependent: :destroy
  has_many :study_sessions, dependent: :destroy
  has_many :learn_sessions, dependent: :destroy
  has_many :test_sessions, dependent: :destroy
  accepts_nested_attributes_for :flashcards,
    reject_if: :all_blank,
    allow_destroy: true

  attr_accessor :validate_card_count

  scope :public_decks, -> { where(visibility: "public") }
  scope :popular, -> { order(forks_count: :desc, created_at: :desc) }

  validates :name, presence: true, length: { maximum: 100 }
  validates :visibility, inclusion: { in: %w[private public] }
  validate :minimum_flashcard_count

  def public? = visibility == "public"
  def private? = visibility == "private"

  def tag_list
    return [] if subject_tags.blank?
    subject_tags.split(",").map(&:strip).reject(&:blank?)
  end

  def tag_list=(tags_string)
    self.subject_tags = tags_string.to_s.split(",").map(&:strip).reject(&:blank?).join(", ")
  end

  private

  def minimum_flashcard_count
    return unless validate_card_count
    active = flashcards.reject(&:marked_for_destruction?)
    errors.add(:base, :minimum_cards) if active.size < 2
  end
end
