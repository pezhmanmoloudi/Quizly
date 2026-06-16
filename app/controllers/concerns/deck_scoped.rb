module DeckScoped
  extend ActiveSupport::Concern

  private

  def set_deck
    @deck = Deck.find(params[:id])
  end

  # Handles all three access states explicitly:
  #   :allowed  → fall through (controller action continues)
  #   :locked   → redirect to unlock page and halt
  #   :denied   → raise NotAuthorizedError (caught by ApplicationController rescue_from)
  def resolve_access
    @access = Decks::AccessService.evaluate(deck: @deck, user: Current.user, session: session)
    case @access.state
    when :locked
      redirect_to unlock_deck_path(@deck) and return
    when :denied
      raise Pundit::NotAuthorizedError
    end
  end

  def set_noindex_for_unlisted
    response.headers["X-Robots-Tag"] = "noindex" if @deck&.unlisted?
  end
end
