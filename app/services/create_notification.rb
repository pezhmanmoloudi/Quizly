class CreateNotification
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
