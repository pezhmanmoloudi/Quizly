class AchievementsController < ApplicationController
  def index
    @all_badges              = Badge.order(:category, :id)
    user_badges              = Current.user.user_badges.load
    @earned_badge_ids        = user_badges.map(&:badge_id).to_set
    @user_badges_by_badge_id = user_badges.index_by(&:badge_id)
    @earned_count            = @earned_badge_ids.size
  end
end
