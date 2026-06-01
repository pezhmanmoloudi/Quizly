class User < ApplicationRecord
  AVATAR_MAX_MB      = 5
  AVATAR_MIN_PX      = 100
  AVATAR_MAX_PX      = 4000
  AVATAR_FORMATS     = %w[image/jpeg image/png image/gif image/webp].freeze
  AVATAR_FORMAT_HINT = "JPG, PNG, GIF, WebP".freeze

  has_secure_password
  has_one_attached :avatar
  has_many :sessions, dependent: :destroy
  has_many :decks, dependent: :destroy
  has_many :card_progresses, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :display_name,  with: ->(n) { n.strip.presence }

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,      length: { minimum: 8 }, allow_nil: true
  validates :display_name,  length: { maximum: 50 }, allow_blank: true
  validate  :avatar_is_valid_image, if: -> { avatar.attached? && avatar.changed? }

  def display_name
    self[:display_name].presence || email_address&.split("@")&.first&.capitalize || ""
  end

  def show_avatar?
    show_avatar && avatar.attached?
  end

  private

  def avatar_is_valid_image
    unless avatar.content_type.in?(AVATAR_FORMATS)
      errors.add(:avatar, "must be #{AVATAR_FORMAT_HINT}")
      return
    end
    if avatar.blob.byte_size > AVATAR_MAX_MB.megabytes
      errors.add(:avatar, "must be smaller than #{AVATAR_MAX_MB}MB")
    end
  end
end
