class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :email_streaks_badges,  default: true, null: false
      t.boolean :email_study_reminders, default: true, null: false
      t.string  :reminder_time,         default: "08:00", null: false
      t.string  :time_zone,             default: "UTC",   null: false
      t.timestamps
    end
  end
end
