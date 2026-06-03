class ExploreController < ApplicationController
  before_action :require_authentication

  def index
    @decks = Deck.public_decks.popular.includes(:user)
    if (@query = params[:q].presence)
      @decks = @decks.where("name LIKE :q OR description LIKE :q", q: "%#{@query}%")
    end
    @decks = @decks.limit(48)
  end
end
