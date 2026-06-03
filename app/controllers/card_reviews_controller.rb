class CardReviewsController < ApplicationController
  def create
    @card_progress = Current.user.card_progresses.find(params[:card_progress_id])
    quality = quality_from_button(params[:rating])
    Sm2Scheduler.grade_card(@card_progress, quality)

    deck = @card_progress.flashcard.deck
    correct = quality >= 4

    session[:"study_reviewed_#{deck.id}"] = (session[:"study_reviewed_#{deck.id}"] || 0) + 1
    session[:"study_correct_#{deck.id}"]  = (session[:"study_correct_#{deck.id}"]  || 0) + (correct ? 1 : 0)

    more_due = Current.user.card_progresses
                           .due
                           .unscope(:order)
                           .joins(:flashcard)
                           .where(flashcards: { deck_id: deck.id })
                           .exists?

    if more_due
      redirect_to study_deck_path(deck)
    else
      reviewed = session.delete(:"study_reviewed_#{deck.id}") || 1
      correct  = session.delete(:"study_correct_#{deck.id}")  || 0
      session.delete(:"study_total_#{deck.id}")
      redirect_to study_deck_path(deck),
        flash: { study_summary: { reviewed: reviewed, correct: correct } }
    end
  end

  private

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
