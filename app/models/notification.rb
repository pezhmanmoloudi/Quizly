class Notification < ApplicationRecord
  VALID_EVENT_TYPES = %w[badge_earned followed deck_commented deck_reacted].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor,     class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :event_type, inclusion: { in: VALID_EVENT_TYPES }

  scope :unread,  -> { where(read: false) }
  scope :recent,  -> { order(created_at: :desc).limit(20) }

  def mark_read!
    update!(read: true, read_at: Time.current) unless read?
  end
end
