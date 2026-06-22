class NotificationPreference < ApplicationRecord
  REMINDER_TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  belongs_to :user

  validates :reminder_time, format: { with: REMINDER_TIME_FORMAT }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  # Named predicates for future email delivery code — avoids raw attribute reads
  # and makes it clear these are email-channel preferences, not in-app preferences.
  def badge_email_enabled?    = email_streaks_badges?
  def reminder_email_enabled? = email_study_reminders?
end
