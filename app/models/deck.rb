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

  has_secure_password :access_password, validations: false

  attribute :visibility,      :string, default: "everyone"
  attribute :edit_permission, :string, default: "owner_only"

  VISIBILITY_VALUES      = %w[everyone unlisted password_protected private].freeze
  EDIT_PERMISSION_VALUES = %w[owner_only password_users].freeze
  FORKABLE_VISIBILITIES  = %w[private unlisted everyone].freeze

  after_destroy :decrement_source_forks_count

  scope :discoverable,        -> { where(visibility: %w[everyone password_protected]) }
  scope :visible_in_explore,  -> { discoverable }
  scope :searchable,          -> { discoverable }
  scope :publicly_visible,    -> { discoverable }
  scope :public_decks,        -> { discoverable }
  scope :popular,             -> { order(forks_count: :desc, created_at: :desc) }
  scope :accessible_by_token, ->(token) { where(visibility: "unlisted", share_token: token) }

  before_create :generate_share_token

  validates :name,            presence: true, length: { maximum: 100 }
  validates :visibility,      inclusion: { in: VISIBILITY_VALUES }
  validates :edit_permission, inclusion: { in: EDIT_PERMISSION_VALUES }
  validate  :edit_permission_compatible_with_visibility
  validate  :access_password_requirements

  # ── Predicates ────────────────────────────────────────────────────────────

  def everyone?           = visibility == "everyone"
  def unlisted?           = visibility == "unlisted"
  def password_protected? = visibility == "password_protected"
  def private?            = visibility == "private"
  def public?             = everyone?

  # ── Authorization ─────────────────────────────────────────────────────────

  def can_view?(user, session_auth:, share_auth: false)
    return true if everyone?
    return true if user&.id == user_id
    return true if unlisted? && share_auth
    return true if password_protected? && session_auth
    false
  end

  def can_edit?(user, session_auth:)
    return false if user.nil?
    return true if user.id == user_id
    return true if edit_permission == "password_users" && session_auth
    false
  end

  def can_edit_settings?(user)
    user&.id == user_id
  end

  def can_delete?(user)
    user&.id == user_id
  end

  def can_manage_cards?(user, session_auth:)
    can_edit?(user, session_auth: session_auth)
  end

  def can_fork?(user)
    return false if private? && user&.id != user_id
    true
  end

  def preview_accessible?
    everyone? || password_protected?
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

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(32)
  end

  def decrement_source_forks_count
    Deck.where(id: forked_from_id).update_counters(forks_count: -1) if forked_from_id
  end

  def edit_permission_compatible_with_visibility
    if visibility == "private" && edit_permission == "password_users"
      errors.add(:edit_permission, :invalid_for_private_deck)
    end
    if visibility == "unlisted" && edit_permission == "password_users"
      errors.add(:edit_permission, :invalid_for_unlisted_deck)
    end
  end

  def access_password_requirements
    needs_password = visibility == "password_protected" || edit_permission == "password_users"
    if needs_password && access_password_digest.blank? && access_password.blank?
      errors.add(:access_password, :blank)
    end
    if access_password.present?
      errors.add(:access_password, :too_short, count: 8)  if access_password.length < 8
      errors.add(:access_password, :too_long,  count: 128) if access_password.length > 128
    end
  end
end
