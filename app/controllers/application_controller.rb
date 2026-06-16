class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :load_sidebar_decks

  rescue_from ActiveRecord::RecordNotFound, with: :redirect_not_found
  rescue_from Pundit::NotAuthorizedError,   with: :pundit_not_authorized

  private

  def pundit_user = Current.user

  def redirect_not_found
    flash[:alert] = t("errors.not_found.flash")
    redirect_to fallback_destination
  end

  def pundit_not_authorized
    flash[:alert] = t("errors.not_authorized.flash")
    redirect_to fallback_destination
  end

  def fallback_destination
    authenticated? ? decks_path : explore_path
  end

  def set_locale
    resume_session
    locale = Current.user&.locale.to_s
    I18n.locale = Language::LANGUAGES.key?(locale) ? locale : I18n.default_locale
  end

  def load_sidebar_decks
    return unless authenticated?
    @sidebar_decks = Current.user.decks.order(updated_at: :desc).limit(20)
  end
end
