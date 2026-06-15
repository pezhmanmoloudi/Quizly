class Deck < ApplicationRecord
  belongs_to :user
  belongs_to :source_deck, class_name: "Deck", optional: true
  has_many :library_items, dependent: :destroy
  has_many :savers, through: :library_items, source: :user
  has_many :flashcards, dependent: :destroy
  has_many :study_sessions, dependent: :destroy
  has_many :learn_sessions, dependent: :destroy
  has_many :test_sessions, dependent: :destroy
  accepts_nested_attributes_for :flashcards,
    reject_if: :all_blank,
    allow_destroy: true

  has_secure_password :password, validations: false

  attribute :visibility,      :string, default: "private"
  attribute :edit_permission, :string, default: "only_me"

  VISIBILITY_VALUES      = %w[public unlisted private].freeze
  EDIT_PERMISSION_VALUES = %w[only_me people_with_password].freeze
  DUPLICATE_VISIBILITIES = %w[private unlisted public].freeze

  scope :discoverable, -> { where(visibility: "public") }
  scope :popular,      -> { order(created_at: :desc) }

  validates :name,            presence: true, length: { maximum: 100 }
  validates :visibility,      inclusion: { in: VISIBILITY_VALUES }
  validates :edit_permission, inclusion: { in: EDIT_PERMISSION_VALUES }
  validate  :edit_permission_compatible_with_visibility
  validate  :password_requirements

  # ── Unlock state (stamped by controller from session) ─────────────────────

  attr_writer :unlocked
  def unlocked? = !!@unlocked

  # ── Predicates ────────────────────────────────────────────────────────────

  def public?               = visibility == "public"
  def unlisted?             = visibility == "unlisted"
  def private?              = visibility == "private"

  def only_me?              = edit_permission == "only_me"
  def people_with_password? = edit_permission == "people_with_password"

  # ── Authorization ─────────────────────────────────────────────────────────

  def can_view?(user)
    return true if public?
    return true if user&.id == user_id
    return false if private?
    # unlisted: freely accessible when no password is set; otherwise require unlock
    password_digest.blank? || unlocked?
  end

  def can_edit?(user)
    return false if user.nil?
    return true if user.id == user_id
    return false if private?
    unlocked? && people_with_password?
  end

  def can_edit_settings?(user)
    user&.id == user_id
  end

  def can_delete?(user)
    user&.id == user_id
  end

  def can_save?(user)
    return false if private? && user&.id != user_id
    true
  end

  def can_copy?(user)
    return false if user.nil?
    return false if user.id == user_id
    public? || unlisted?
  end

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

  def edit_permission_compatible_with_visibility
    return unless visibility == "private" && edit_permission == "people_with_password"
    errors.add(:edit_permission, :invalid_for_private_deck)
  end

  def password_requirements
    if people_with_password? && password_digest.blank? && password.blank?
      errors.add(:password, :blank)
    end
    if password.present?
      errors.add(:password, :too_short, count: 8)  if password.length < 8
      errors.add(:password, :too_long,  count: 128) if password.length > 128
    end
  end
end
