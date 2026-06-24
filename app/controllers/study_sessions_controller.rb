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
    @new_limit  = params.key?(:new_limit) ? params[:new_limit].to_i : 10
    @priority   = params[:priority] == "hardest" ? "hardest" : "due"

    base_scope = Current.user.card_progresses
                             .joins(:flashcard)
                             .where(flashcards: { deck_id: @deck.id })
    base_scope = base_scope.starred if @study_mode == "starred"

    review_due = base_scope.due.where.not(repetitions: 0)
    review_due = review_due.reorder(ease_factor: :asc) if @priority == "hardest"

    new_due_all = base_scope.due.where(repetitions: 0)
    new_due     = @new_limit.positive? ? new_due_all.limit(@new_limit) : new_due_all

    review_count = review_due.unscope(:order).count
    capped_new   = @new_limit.positive? ? [ new_due_all.count, @new_limit ].min : new_due_all.count
    @cards_remaining = review_count + capped_new

    @card_progress = review_due.includes(:flashcard).first ||
                     new_due.includes(:flashcard).first

    if @card_progress.present?
      @study_session = Decks::StudySessionService.find_or_create(
        deck:       @deck,
        user:       Current.user,
        session_id: session[:study_session_id],
        due_count:  @cards_remaining
      )
      session[:study_session_id] = @study_session.id
      @cards_total = @study_session.cards_total
      @streak      = session[:study_streak].to_i
    else
      session.delete(:study_session_id)
      session.delete(:study_streak)
    end
  end
end
