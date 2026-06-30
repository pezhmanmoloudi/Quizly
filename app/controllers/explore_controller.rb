class ExploreController < ApplicationController
  allow_unauthenticated_access only: [:index]

  def index
    @decks = Deck.discoverable.popular.includes(:user, :flashcards)
    @query = params[:q].presence
    @decks = @decks.search(@query) if @query
    @decks = @decks.limit(48)
  end
end
