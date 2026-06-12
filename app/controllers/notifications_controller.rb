class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :mark_read ]

  def index
    @notifications = Current.user.notifications.recent.includes(:actor)
  end

  def badge
    @unread_count = Current.user.notifications.unread.count
  end

  def mark_read
    @notification.mark_read!
    @unread_count = Current.user.notifications.unread.count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path }
    end
  end

  def mark_all_read
    Current.user.notifications.unread.update_all(read: true, read_at: Time.current)
    @unread_count = 0
    @notifications = Current.user.notifications.recent.includes(:actor)
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
