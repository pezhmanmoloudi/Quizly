class Notification < ApplicationRecord
  VALID_EVENT_TYPES = %w[
    badge_earned
    followed
    followed_user_published_deck
    deck_commented
    deck_reacted
  ].freeze
  # badge_earned   → implemented via BadgeAwarder
  # followed       → planned, no call site yet
  # deck_commented → planned, no call site yet
  # deck_reacted   → planned, no call site yet

  belongs_to :recipient, class_name: "User"
  belongs_to :actor,     class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :event_type, inclusion: { in: VALID_EVENT_TYPES }

  scope :unread,  -> { where(read: false) }
  scope :recent,  -> { order(created_at: :desc).limit(20) }

  # Broadcast after full DB commit so receivers always find the persisted record.
  after_create_commit  :broadcast_badge_update
  after_update_commit  :broadcast_badge_update, if: :saved_change_to_read?

  def mark_read!
    update!(read: true, read_at: Time.current) unless read?
  end

  private

  def broadcast_badge_update
    unread_count = recipient.notifications.unread.count
    broadcast_update_to(
      [ recipient, "notifications" ],
      target:  "notification-badge-inner",
      partial: "notifications/badge_count",
      locals:  { unread_count: unread_count }
    )
  end
end
