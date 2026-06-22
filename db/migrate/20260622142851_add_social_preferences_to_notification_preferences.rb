class AddSocialPreferencesToNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    # Follow notifications: received when someone follows the user
    add_column :notification_preferences, :in_app_follows,            :boolean, null: false, default: true
    add_column :notification_preferences, :email_follows,             :boolean, null: false, default: false

    # Following activity: received when a followed user publishes a deck
    add_column :notification_preferences, :in_app_following_activity, :boolean, null: false, default: true
    add_column :notification_preferences, :email_following_activity,  :boolean, null: false, default: false
  end
end
