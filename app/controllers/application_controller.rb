class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Pagy::Method
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :load_sidebar_decks

  rescue_from ActiveRecord::RecordNotFound, with: :redirect_not_found
  rescue_from Pundit::NotAuthorizedError,   with: :deny_access

  private

  def current_user
    Current.user
  end

  def redirect_not_found
    flash[:alert] = t("errors.not_found.flash")
    redirect_to fallback_destination
  end

  def deny_access(_exception)
    flash[:alert] = t("errors.not_authorized")
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

  def deck_unlocked?(deck)
    session["deck_#{deck.id}_unlocked"] == true
  end
end
