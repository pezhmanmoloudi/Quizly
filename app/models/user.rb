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
  has_many :follows_as_follower, class_name: "Follow", foreign_key: :follower_id,
                                 dependent: :destroy, inverse_of: :follower
  has_many :follows_as_followed, class_name: "Follow", foreign_key: :followed_id,
                                 dependent: :destroy, inverse_of: :followed
  has_many :following, through: :follows_as_follower, source: :followed
  has_many :followers, through: :follows_as_followed, source: :follower

  before_validation :assign_username_from_email, if: -> { username.blank? && email_address.present? }

  after_create :create_notification_preference!

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :display_name,  with: ->(n) { n.strip.presence }
  normalizes :username,      with: ->(u) { u.strip.downcase }

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,      length: { minimum: 8 }, allow_nil: true
  validates :display_name,  length: { maximum: 50 }, allow_blank: true
  validates :locale,        inclusion: { in: LANGUAGES.keys }
  validates :username,      presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: /\A[a-z0-9_]+\z/, message: :invalid_username },
                            length: { minimum: 3, maximum: 30 }
  validate  :avatar_is_valid_image, if: -> { avatar.attached? && avatar.changed? }

  def to_param = username

  def display_name
    self[:display_name].presence || email_address&.split("@")&.first&.capitalize || ""
  end

  def show_avatar?
    avatar.attached? && avatar.blob.persisted?
  end

  def following?(other_user)
    follows_as_follower.exists?(followed_id: other_user.id)
  end

  def self.find_or_create_from_google(auth)
    find_by(google_uid: auth.uid) ||
      find_by(email_address: auth.info.email)&.tap { |u| u.update(google_uid: auth.uid) } ||
      create(
        email_address: auth.info.email,
        google_uid:    auth.uid,
        display_name:  auth.info.name,
        password:      SecureRandom.base64(24)
      )
  end

  private

  def assign_username_from_email
    base = email_address.split("@").first.downcase.gsub(/[^a-z0-9_]/, "_")
    base = "user" if base.length < 3
    candidate = base
    n = 1
    while self.class.exists?(username: candidate)
      candidate = "#{base}_#{n}"
      n += 1
    end
    self.username = candidate
  end

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
