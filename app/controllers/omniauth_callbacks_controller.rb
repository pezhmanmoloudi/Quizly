class OmniauthCallbacksController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: %i[google_oauth2 github failure]

  def google_oauth2
    handle_callback(:google_oauth2, t("sessions.google.success"), t("sessions.google.failure"))
  end

  def github
    handle_callback(:github, t("sessions.github.success"), t("sessions.github.failure"))
  end

  def failure
    Rails.logger.warn "[Auth][OAuth] failure endpoint hit — strategy=#{params[:strategy]} message=#{params[:message]}"
    redirect_to login_path, alert: t("sessions.errors.oauth_failure")
  end

  private

  def handle_callback(provider, success_msg, failure_msg)
    Rails.logger.info "[Auth][OAuth] #{provider} — handle_callback entered"

    auth   = request.env["omniauth.auth"]
    result = OAuthCallbackService.call(provider, auth)

    if result.ok
      start_new_session_for result.user
      Rails.logger.info "[Auth][OAuth] #{provider} — session created for user id=#{result.user.id}"
      redirect_to after_authentication_url, notice: success_msg
    else
      Rails.logger.warn "[Auth][OAuth] #{provider} — failed: reason=#{result.reason} error=#{result.error}"
      redirect_to login_path, alert: failure_msg
    end
  end
end
