class LearnFeedbacksController < ApplicationController
  VALID_FEEDBACKS = %w[got_it confused dont_know].freeze

  def create
    item = find_item
    return head :not_found unless item

    learn_session = item.learn_session
    was_mastered  = item.mastered?
    threshold     = learn_session.deck.learn_mastery_threshold

    item.record_feedback!(feedback_param, mastery_threshold: threshold)
    learn_session.increment!(:cards_mastered) if !was_mastered && item.mastered?

    session_complete = learn_session.reload
                                    .learn_session_items
                                    .where.not(status: "mastered")
                                    .none?

    if session_complete && !learn_session.finished?
      learn_session.update!(finished_at: Time.current)
      session.delete(:learn_session_id) if session[:learn_session_id] == learn_session.id
      StreakUpdater.call(Current.user)
      BadgeAwarder.call(Current.user)
    end

    render json: {
      mastery_score:    item.mastery_score,
      status:           item.status,
      session_complete: session_complete
    }
  end

  private

  def find_item
    item = LearnSessionItem.includes(learn_session: :deck).find_by(id: params[:learn_session_item_id])
    return nil unless item&.learn_session&.user_id == Current.user.id

    item
  end

  def feedback_param
    fb = params[:feedback].to_s
    raise ActionController::BadRequest unless VALID_FEEDBACKS.include?(fb)

    fb
  end
end
