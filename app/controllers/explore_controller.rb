class ExploreController < ApplicationController
  allow_unauthenticated_access only: [:index]

  def index
    @decks = Deck.discoverable.popular.includes(:user, :flashcards)
    if (@query = params[:q].presence)
      @decks = @decks.where("name LIKE :q OR description LIKE :q", q: "%#{@query}%")
    end
    @decks = @decks.limit(48)
  end
end
