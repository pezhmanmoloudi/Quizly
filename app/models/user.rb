class User < ApplicationRecord
  include Language

  AVATAR_MAX_MB  = 5
  AVATAR_FORMATS = %w[image/jpeg image/png image/webp].freeze

  has_secure_password
  has_one_attached :avatar
  has_many :sessions, dependent: :destroy
  has_many :decks, dependent: :destroy
  has_many :card_progresses, dependent: :destroy
  has_many :study_sessions, dependent: :destroy
  has_many :learn_sessions, dependent: :destroy
  has_many :test_sessions, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy, inverse_of: :recipient
  has_many :sent_notifications, class_name: "Notification", foreign_key: :actor_id,
                                dependent: :nullify, inverse_of: :actor
  has_one :notification_preference, dependent: :destroy
  has_many :folders, dependent: :destroy

  after_create :create_notification_preference!

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :display_name,  with: ->(n) { n.strip.presence }

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,      length: { minimum: 8 }, allow_nil: true
  validates :display_name,  length: { maximum: 50 }, allow_blank: true
  validates :locale,        inclusion: { in: LANGUAGES.keys }
  validate  :avatar_is_valid_image, if: -> { avatar.attached? && avatar.changed? }

  def display_name
    self[:display_name].presence || email_address&.split("@")&.first&.capitalize || ""
  end

  def show_avatar?
    avatar.attached? && avatar.blob.persisted?
  end

  private

  def avatar_is_valid_image
    unless avatar.content_type.in?(AVATAR_FORMATS)
      errors.add(:avatar, I18n.t("accounts.avatar_format_error"))
      return
    end
    if avatar.blob.byte_size > AVATAR_MAX_MB.megabytes
      errors.add(:avatar, I18n.t("accounts.avatar_size_error"))
    end
  end
end
