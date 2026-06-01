class User < ApplicationRecord
  AVATAR_MAX_MB     = 5
  AVATAR_FORMATS    = %w[image/jpeg image/png image/webp].freeze
  AVATAR_ERR_FORMAT = "Invalid file format. Please upload JPG, PNG, or WEBP.".freeze
  AVATAR_ERR_SIZE   = "Profile picture must be smaller than 5 MB.".freeze

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
    avatar.attached? && avatar.blob.persisted?
  end

  private

  def avatar_is_valid_image
    unless avatar.content_type.in?(AVATAR_FORMATS)
      errors.add(:avatar, AVATAR_ERR_FORMAT)
      return
    end
    if avatar.blob.byte_size > AVATAR_MAX_MB.megabytes
      errors.add(:avatar, AVATAR_ERR_SIZE)
    end
  end
end
