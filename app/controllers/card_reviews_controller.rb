class CardReviewsController < ApplicationController
  def create
    @card_progress = Current.user.card_progresses.find(params[:card_progress_id])
    was_new_card = @card_progress.repetitions == 0
    quality = quality_from_button(params[:rating])
    Sm2Scheduler.grade_card(@card_progress, quality)

    case params[:rating]
    when "again" then session[:study_streak] = 0
    when "good", "easy" then session[:study_streak] = session[:study_streak].to_i + 1
    end

    session[:new_cards_reviewed] = session[:new_cards_reviewed].to_i + 1 if was_new_card

    deck = @card_progress.flashcard.deck
    correct = quality >= 4
    study_mode = params[:study_mode].presence || "all"

    study_session = load_study_session(deck)
    if study_session
      increments = { cards_reviewed: 1 }
      increments[:cards_correct] = 1 if correct
      StudySession.update_counters(study_session.id, **increments)
      study_session.reload
    end

    new_limit_param    = params[:new_limit].presence
    new_limit          = new_limit_param&.to_i || 10
    priority           = params[:priority].presence
    new_cards_reviewed = session[:new_cards_reviewed].to_i
    new_limit_reached  = new_limit.positive? && new_cards_reviewed >= new_limit

    more_due = Current.user.card_progresses
                           .due
                           .unscope(:order)
                           .joins(:flashcard)
                           .where(flashcards: { deck_id: deck.id })
                           .then { |s| study_mode == "starred" ? s.starred : s }
                           .then { |s| new_limit_reached ? s.where.not(repetitions: 0) : s }
                           .exists?

    if more_due
      redirect_to study_deck_path(
        deck,
        mode:      (study_mode == "starred" ? "starred" : nil).presence,
        new_limit: new_limit_param,
        priority:  (priority if priority != "due")
      )
    else
      if study_session && !study_session.finished?
        study_session.update!(finished_at: Time.current)
        StreakUpdater.call(Current.user)
        BadgeAwarder.call(Current.user)
      end
      session.delete(:study_session_id)
      session.delete(:study_streak)
      redirect_to study_deck_path(
        deck,
        mode:      (study_mode == "starred" ? "starred" : nil).presence,
        new_limit: new_limit_param
      ), flash: { study_summary: {
          reviewed: study_session&.cards_reviewed || 1,
          correct:  study_session&.cards_correct  || 0,
          elapsed:  study_session&.elapsed_seconds
        } }
    end
  end

  private

  def load_study_session(deck)
    sid = session[:study_session_id]
    return nil unless sid
    Current.user.study_sessions.find_by(id: sid, finished_at: nil, deck: deck)
  end

  def quality_from_button(rating)
    case rating
    when "again" then 1
    when "hard"  then 3
    when "good"  then 4
    when "easy"  then 5
    else              1
    end
  end
end
