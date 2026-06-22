class NotificationPreferencesController < ApplicationController
  before_action :load_preference

  def show; end

  def update
    if @notification_preference.update(notification_preference_params)
      redirect_to notification_preferences_path, notice: t("accounts.updated.notifications")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_preference
    @notification_preference = Current.user.notification_preference ||
                               Current.user.build_notification_preference
  end

  def notification_preference_params
    params.require(:notification_preference).permit(
      :email_streaks_badges,
      :email_study_reminders,
      :reminder_time,
      :time_zone,
      :in_app_follows,
      :email_follows,
      :in_app_following_activity,
      :email_following_activity
    )
  end
end
