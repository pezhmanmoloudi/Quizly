class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :mark_read ]

  def index
    authorize Notification
    @notifications = Current.user.notifications.recent.includes(:actor)
  end

  def mark_read
    authorize @notification
    @notification.mark_read!
    @unread_count = Current.user.notifications.unread.count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path }
    end
  end

  def mark_all_read
    authorize Notification
    Current.user.notifications.unread.update_all(
      read: true, read_at: Time.current, updated_at: Time.current
    )
    @unread_count   = Current.user.notifications.unread.count
    @notifications  = Current.user.notifications.recent.includes(:actor)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path }
    end
  end

  private

  def set_notification
    @notification = Current.user.notifications.find(params[:id])
  end
end
