class SharedDecksController < ApplicationController
  allow_unauthenticated_access only: [:show]

  def show
    @deck = Deck.accessible_by_token(params[:token]).first
    raise ActiveRecord::RecordNotFound unless @deck

    session["deck_share_#{@deck.id}"] = true
    response.headers["X-Robots-Tag"] = "noindex"

    items = DecksController::ITEMS_PER_PAGE_OPTIONS.include?(params[:items].to_i) ? params[:items].to_i : 10
    @pagy, @flashcards = pagy(@deck.flashcards.order(:position), limit: items)
    @items_per_page = items

    render "decks/show"
  end
end
