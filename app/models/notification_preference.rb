class NotificationPreference < ApplicationRecord
  REMINDER_TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  belongs_to :user

  validates :reminder_time, format: { with: REMINDER_TIME_FORMAT }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
end
