class PasswordsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]
  unless Rails.env.development? || Rails.env.test?
    rate_limit to: 5, within: 10.minutes, only: :create,
               with: -> { redirect_to forgot_password_url, alert: I18n.t("passwords.errors.rate_limited") }
  end

  def new
  end

  def create
    email = params[:email_address].to_s.strip

    if email.blank?
      flash.now[:alert] = t("passwords.errors.blank_email")
      return render :new, status: :unprocessable_entity
    end

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      flash.now[:alert] = t("passwords.errors.invalid_email")
      return render :new, status: :unprocessable_entity
    end

    result = PasswordResetService.call(email)

    case result.reason
    when :email_sent
      redirect_to login_path, notice: t("passwords.sent")
    when :user_not_found
      flash.now[:alert] = t("passwords.errors.email_not_found")
      render :new, status: :unprocessable_entity
    else
      flash.now[:alert] = t("passwords.errors.generic")
      render :new, status: :unprocessable_entity
    end
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
    Rails.logger.warn "[Auth][PasswordReset] Invalid or expired token attempted"
    redirect_to forgot_password_path, alert: t("passwords.invalid")
  end
end
