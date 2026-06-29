class LearnSessionsController < ApplicationController
  include DeckScoped

  before_action :set_deck
  before_action :resolve_access
  before_action :set_noindex_for_unlisted

  def show
    @flashcards = @deck.flashcards.to_a

    if @flashcards.empty?
      @learn_session    = nil
      @learn_items_json = "[]"
      return
    end

    if params[:turbo_action] == "replace" || params[:restart] || params[:weak_only]
      session.delete(:learn_session_id)
    end

    weak_ids = resolve_weak_only_ids

    @learn_session = Decks::LearnSessionService.find_or_create(
      deck:          @deck,
      user:          Current.user,
      session_id:    session[:learn_session_id],
      flashcard_ids: weak_ids
    )

    # Guard against a stale session whose items are all mastered but was never
    # marked finished (e.g. a silently-failed final feedback POST). Left as-is,
    # the JS learn queue resolves empty and hides every card. Finalize it so the
    # completion branch renders and the next visit starts fresh.
    if !@learn_session.finished? &&
        @learn_session.learn_session_items.where.not(status: "mastered").none?
      @learn_session.update!(finished_at: Time.current)
      session.delete(:learn_session_id)
    end

    session[:learn_session_id] = @learn_session.id

    # Render exactly the session's cards. Membership is owned by the backend
    # (build_for caps to learn_new_cards_limit), so the DOM slides always match
    # the persisted LearnSessionItems and the frontend LearnEngine's queue.
    @flashcards = @deck.flashcards.where(
      id: @learn_session.learn_session_items.select(:flashcard_id)
    ).to_a

    # Hydrate the engine from exactly the items that have a rendered slide, so the
    # client item map and the DOM slides stay one-to-one (drops any item whose card
    # was soft-deleted after the session was built).
    rendered_ids = @flashcards.map(&:id).to_set
    @learn_items_json = @learn_session.learn_session_items
      .select { |i| rendered_ids.include?(i.flashcard_id) }
      .map { |i|
        { id: i.id, flashcard_id: i.flashcard_id,
          mastery_score: i.mastery_score, status: i.status }
      }.to_json

    @learn_settings_json = {
      masteryThreshold:  @deck.learn_mastery_threshold,
      weakCardsPriority: @deck.learn_weak_cards_priority,
      newCardsLimit:     @deck.learn_new_cards_limit,
      hintsEnabled:      @deck.learn_hints_enabled
    }.to_json
  end

  private

  def resolve_weak_only_ids
    return nil unless params[:weak_only]
    prev = Current.user.learn_sessions.where(deck: @deck).order(created_at: :desc).first
    return nil unless prev
    ids = prev.learn_session_items
      .where("mastery_score < ?", @deck.learn_mastery_threshold)
      .pluck(:flashcard_id)
    ids.present? ? ids : nil
  end
end
