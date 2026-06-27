class OmniauthCallbacksController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: %i[google_oauth2 failure]

  def google_oauth2
    auth = request.env["omniauth.auth"]

    unless valid_oauth_auth?(auth)
      Rails.logger.warn "[OmniAuth] Invalid or missing auth hash from Google"
      redirect_to login_path, alert: t("sessions.google.failure") and return
    end

    user = User.find_or_create_from_google(auth)

    if user.persisted?
      start_new_session_for user
      redirect_to after_authentication_url, notice: t("sessions.google.success")
    else
      Rails.logger.warn "[OmniAuth] User not persisted. Errors: #{user.errors.full_messages.join(', ')}"
      redirect_to login_path, alert: t("sessions.google.failure")
    end
  end

  def failure
    redirect_to login_path, alert: t("sessions.google.failure")
  end

  private

  def valid_oauth_auth?(auth)
    auth.present? &&
      auth.uid.present? &&
      auth.info&.email.present?
  end
end
