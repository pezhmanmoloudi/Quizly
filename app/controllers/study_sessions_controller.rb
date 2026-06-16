class StudySessionsController < ApplicationController
  include DeckScoped

  before_action :set_deck,                 only: [ :show ]
  before_action :resolve_access,           only: [ :show ]
  before_action :set_noindex_for_unlisted, only: [ :show ]

  def index
    @study_sessions = Current.user.study_sessions
                                  .completed
                                  .includes(:deck)
                                  .recent
                                  .limit(50)
  end

  def show
    CardProgress.initialize_for_deck(@deck, Current.user)

    @study_mode = params[:mode] == "starred" ? "starred" : "all"

    due_scope = Current.user.card_progresses
                            .due
                            .joins(:flashcard)
                            .where(flashcards: { deck_id: @deck.id })
    due_scope = due_scope.starred if @study_mode == "starred"

    @cards_remaining = due_scope.unscope(:order).count
    @card_progress   = due_scope.includes(:flashcard).first

    if @card_progress.present?
      @study_session = Decks::StudySessionService.find_or_create(
        deck:       @deck,
        user:       Current.user,
        session_id: session[:study_session_id],
        due_count:  @cards_remaining
      )
      session[:study_session_id] = @study_session.id
      @cards_total = @study_session.cards_total
      @cards_done  = @cards_total - @cards_remaining
      @streak      = session[:study_streak].to_i
    else
      session.delete(:study_session_id)
      session.delete(:study_streak)
    end
  end
end
