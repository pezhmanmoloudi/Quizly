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

    weak_ids    = resolve_weak_only_ids
    @flashcards = @deck.flashcards.where(id: weak_ids).to_a if weak_ids

    @learn_session = Decks::LearnSessionService.find_or_create(
      deck:          @deck,
      user:          Current.user,
      session_id:    session[:learn_session_id],
      flashcard_ids: weak_ids
    )
    session[:learn_session_id] = @learn_session.id

    @learn_items_json = @learn_session.learn_session_items.map { |i|
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
