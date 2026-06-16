class LearnSessionsController < ApplicationController
  include DeckScoped

  before_action :set_deck
  before_action :resolve_access
  before_action :set_noindex_for_unlisted

  def show
    flashcards = @deck.flashcards.to_a
    if flashcards.empty?
      @learn_session = nil
      @current_item  = nil
      return
    end

    if params[:turbo_action] == "replace" || params[:restart]
      session.delete(:learn_session_id)
    end

    @learn_session = Decks::LearnSessionService.find_or_create(
      deck:       @deck,
      user:       Current.user,
      session_id: session[:learn_session_id]
    )
    session[:learn_session_id] = @learn_session.id
    @current_item = @learn_session.next_item

    if @current_item.nil? && !@learn_session.finished?
      @learn_session.update!(finished_at: Time.current)
    end
  end
end
