class CardProgressesController < ApplicationController
  before_action :set_card_progress

  def grade
    quality = params[:quality].to_i.clamp(1, 5)
    Sm2Scheduler.grade_card(@card_progress, quality)

    render json: {
      id:               @card_progress.id,
      flashcard_id:     @card_progress.flashcard_id,
      ease_factor:      @card_progress.ease_factor,
      interval:         @card_progress.interval,
      repetitions:      @card_progress.repetitions,
      next_review_at:   @card_progress.next_review_at&.iso8601,
      last_reviewed_at: @card_progress.last_reviewed_at&.iso8601
    }
  end

  private

  def set_card_progress
    @card_progress = Current.user.card_progresses.find(params[:id])
  end
end
