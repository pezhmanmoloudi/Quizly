class NotificationPreference < ApplicationRecord
  REMINDER_TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  belongs_to :user

  validates :reminder_time, format: { with: REMINDER_TIME_FORMAT }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  # Named predicates — avoids raw attribute reads and documents channel intent.
  def badge_email_enabled?    = email_streaks_badges?
  def reminder_email_enabled? = email_study_reminders?

  # Social: follow notifications (received when someone follows the user)
  def follow_in_app_enabled?  = in_app_follows?
  def follow_email_enabled?   = email_follows?

  # Following activity (received when a followed user publishes a deck)
  def following_activity_in_app_enabled?  = in_app_following_activity?
  def following_activity_email_enabled?   = email_following_activity?
end
