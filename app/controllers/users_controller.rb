class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    @user  = User.find_by!(username: params[:username])
    @decks = policy_scope(@user.decks.discoverable.order(created_at: :desc))
    authorize @user
  end
end
