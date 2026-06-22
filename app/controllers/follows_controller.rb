class FollowsController < ApplicationController
  before_action :set_followed_user

  def create
    @follow = Current.user.follows_as_follower.build(followed: @followed_user)
    authorize @follow

    if @follow.save
      if @followed_user.notification_preference.in_app_follows?
        CreateNotification.call(
          recipient:  @followed_user,
          event_type: "followed",
          actor:      Current.user,
          notifiable: @follow
        )
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to user_path(@followed_user) }
      end
    else
      # Graceful handling of DB unique violation (race condition duplicate follow).
      # Return the "already following" button state rather than a 500.
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "follow-button-#{@followed_user.id}",
            partial: "follows/follow_button",
            locals:  { followed_user: @followed_user, following: true }
          )
        end
        format.html { redirect_to user_path(@followed_user) }
      end
    end
  end

  def destroy
    # Scoped to Current.user — prevents IDOR: a user can never destroy another user's follow.
    @follow = Current.user.follows_as_follower.find_by!(followed: @followed_user)
    authorize @follow
    @follow.destroy
    # No unfollow notification — industry convention; notifying on unfollow is hostile UX.

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to user_path(@followed_user) }
    end
  end

  private

  def set_followed_user
    @followed_user = User.find_by!(username: params[:user_username])
  end
end
