class Deck < ApplicationRecord
  belongs_to :user
  belongs_to :source_deck, class_name: "Deck", optional: true
  has_many :library_items, dependent: :destroy
  has_many :savers, through: :library_items, source: :user
  has_many :flashcards, dependent: :destroy
  before_destroy :purge_soft_deleted_flashcards
  has_many :study_sessions, dependent: :destroy
  has_many :learn_sessions, dependent: :destroy
  has_many :test_sessions, dependent: :destroy
  has_many :deck_folders, dependent: :destroy
  has_many :folders, through: :deck_folders
  accepts_nested_attributes_for :flashcards,
    reject_if: :all_blank,
    allow_destroy: true

  has_secure_password :password, validations: false

  attribute :visibility,  :string, default: "private"
  attribute :access_mode, :string, default: "open"

  VISIBILITY_VALUES      = %w[public unlisted private].freeze
  ACCESS_MODE_VALUES     = %w[open password].freeze
  DUPLICATE_VISIBILITIES = %w[private unlisted public].freeze

  scope :complete,     -> { where(flashcards_count: 1..) }
  scope :discoverable, -> { complete.where(visibility: "public") }
  scope :popular,      -> { order(created_at: :desc) }

  validates :name,        presence: true, length: { maximum: 100 }
  validates :visibility,  inclusion: { in: VISIBILITY_VALUES }
  validates :access_mode, inclusion: { in: ACCESS_MODE_VALUES }
  validate  :access_mode_compatible_with_visibility
  validate  :password_requirements
  validate  :completeness_for_sharing, on: :update

  # ── Predicates ────────────────────────────────────────────────────────────

  def public?             = visibility == "public"
  def unlisted?           = visibility == "unlisted"
  def private?            = visibility == "private"

  def open?               = access_mode == "open"
  def password_protected? = access_mode == "password"

  def complete? = name.present? && flashcards.exists?
  def draft?    = !complete?

  def saved_by?(user)
    return false unless user
    library_items.exists?(user: user)
  end

  def preview_accessible?
    public?
  end

  # ── Tags ──────────────────────────────────────────────────────────────────

  def tag_list
    return [] if subject_tags.blank?
    subject_tags.split(",").map(&:strip).reject(&:blank?)
  end

  def tag_list=(tags_string)
    self.subject_tags = tags_string.to_s.split(",").map(&:strip).reject(&:blank?).join(", ")
  end

  private

  def purge_soft_deleted_flashcards
    Flashcard.unscoped.where(deck_id: id).where.not(deleted_at: nil).delete_all
  end

  def completeness_for_sharing
    return if private?
    return if flashcards.exists?
    errors.add(:base, :not_ready_to_share)
  end

  def access_mode_compatible_with_visibility
    return unless visibility == "private" && access_mode == "password"
    errors.add(:access_mode, :invalid_for_private_deck)
  end

  def password_requirements
    if password_protected? && password_digest.blank? && password.blank?
      errors.add(:password, :blank)
    end
    if password.present?
      errors.add(:password, :too_short, count: 8)  if password.length < 8
      errors.add(:password, :too_long,  count: 128) if password.length > 128
    end
  end
end
