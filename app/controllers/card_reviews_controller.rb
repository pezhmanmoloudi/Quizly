class CardReviewsController < ApplicationController
  def create
    @card_progress = Current.user.card_progresses.find(params[:card_progress_id])
    quality = quality_from_button(params[:rating])

    Sm2Scheduler.grade_card(@card_progress, quality)

    redirect_to study_deck_path(@card_progress.flashcard.deck_id)
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
