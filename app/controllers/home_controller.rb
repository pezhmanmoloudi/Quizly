class HomeController < ApplicationController
  allow_unauthenticated_access only: [:index]

  def index
    redirect_to dashboard_path and return if authenticated?
    @featured_decks = Deck.public_decks.popular.includes(:user, :flashcards).limit(6)
  end
end
