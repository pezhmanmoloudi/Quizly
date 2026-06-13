class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :load_sidebar_decks

  private

  def set_locale
    resume_session
    locale = Current.user&.locale.to_s
    I18n.locale = Language::LANGUAGES.key?(locale) ? locale : I18n.default_locale
  end

  def load_sidebar_decks
    return unless authenticated?
    @sidebar_decks = Current.user.decks.order(updated_at: :desc).limit(20)
  end

  def deck_session_auth(deck)
    session["deck_auth_#{deck.id}"] == true
  end
end
