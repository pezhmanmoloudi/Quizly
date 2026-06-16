class TestSessionsController < ApplicationController
  include DeckScoped

  before_action :set_deck
  before_action :resolve_access
  before_action :set_noindex_for_unlisted

  def show
    flashcards = @deck.flashcards.to_a
    if flashcards.empty?
      @test_session = nil
      return
    end

    if params[:turbo_action] == "replace" || params[:restart]
      session.delete(:test_session_id)
    end

    @test_session = Decks::TestSessionService.find_or_create(
      deck:       @deck,
      user:       Current.user,
      session_id: session[:test_session_id],
      flashcards: flashcards
    )
    session[:test_session_id] = @test_session.id

    if @test_session.finished?
      @test_session = nil
    end
  end
end
