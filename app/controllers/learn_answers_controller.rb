class LearnAnswersController < ApplicationController
  def create
    @item = find_item
    return head :not_found unless @item

    @learn_session = @item.learn_session
    @correct = answer_correct?(@item.flashcard, params[:answer])

    if @correct
      was_mastered = @item.mastered?
      @item.record_correct!
      @learn_session.increment!(:cards_mastered) if !was_mastered && @item.mastered?
    else
      @item.record_incorrect!
    end

    @next_item = @learn_session.next_item

    if @next_item.nil? && !@learn_session.finished?
      @learn_session.update!(finished_at: Time.current)
      StreakUpdater.call(Current.user)
      BadgeAwarder.call(Current.user)
      session.delete(:learn_session_id)
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def find_item
    Current.user.learn_sessions
           .joins(:learn_session_items)
           .where(learn_session_items: { id: params[:learn_session_item_id] })
           .first
           &.learn_session_items
           &.find_by(id: params[:learn_session_item_id])
  end

  def answer_correct?(flashcard, answer)
    normalize(answer) == normalize(flashcard.back_content)
  end

  def normalize(str)
    str.to_s.strip.downcase.gsub(/\s+/, " ")
  end
end
