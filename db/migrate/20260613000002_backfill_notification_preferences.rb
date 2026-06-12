class BackfillNotificationPreferences < ActiveRecord::Migration[8.1]
  def up
    User.where.missing(:notification_preference).find_each(&:create_notification_preference!)
  end

  def down
    # intentionally irreversible — can't distinguish backfilled rows from normally-created ones
  end
end
