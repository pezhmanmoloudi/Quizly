class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :show, :following ]

  def show
    @user  = User.find_by!(username: params[:username])
    @decks = policy_scope(@user.decks.discoverable.includes(:flashcards).order(created_at: :desc))
    authorize @user
  end

  def following
    @user      = User.find_by!(username: params[:username])
    @following = @user.following.order("follows.created_at DESC")
    authorize @user, :show?

    @current_user_following_ids =
      authenticated? ? Current.user.follows_as_follower.pluck(:followed_id).to_set : [].to_set
  end
end
