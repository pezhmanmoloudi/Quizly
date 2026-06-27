class OmniauthCallbacksController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: %i[google_oauth2 failure]

  def google_oauth2
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_google(auth)

    if user.persisted?
      start_new_session_for user
      redirect_to after_authentication_url, notice: t("sessions.google.success")
    else
      redirect_to login_path, alert: t("sessions.google.failure")
    end
  end

  def failure
    redirect_to login_path, alert: t("sessions.google.failure")
  end
end
