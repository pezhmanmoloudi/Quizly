class CreateNotification
  # Creates an IN-APP notification record (bell icon) only.
  # Email delivery is a separate concern handled in NotificationMailer — never gate
  # this method on email_streaks_badges or email_study_reminders preferences, as those
  # control email delivery only, not in-app visibility.
  def self.call(recipient:, event_type:, actor: nil, notifiable: nil)
    return unless Notification::VALID_EVENT_TYPES.include?(event_type)

    Notification.create!(
      recipient:  recipient,
      event_type: event_type,
      actor:      actor,
      notifiable: notifiable
    )
  end
end
