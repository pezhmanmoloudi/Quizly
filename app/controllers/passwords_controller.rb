class PasswordsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to forgot_password_url, alert: I18n.t("passwords.errors.rate_limited") }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to login_path, notice: t("passwords.sent")
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to login_path, notice: t("passwords.reset")
    else
      redirect_to reset_password_path(params[:token]), alert: t("passwords.mismatch")
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to forgot_password_path, alert: t("passwords.invalid")
    end
end
