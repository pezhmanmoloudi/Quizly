class User < ApplicationRecord
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

  private

  def avatar_is_valid_image
    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:avatar, "must be a JPEG, PNG, GIF, or WebP image")
    end
    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "must be smaller than 5MB")
    end
  end
end
