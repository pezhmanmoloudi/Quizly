class RegistrationsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: [ :new, :create ]
  before_action :redirect_if_authenticated, only: [ :new, :create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to signup_url, alert: I18n.t("registrations.errors.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      redirect_to dashboard_path, notice: t("registrations.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_authenticated
    redirect_to dashboard_path if authenticated?
  end

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
