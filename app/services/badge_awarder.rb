class BadgeAwarder
  # Thresholds below are mirrored as targets in BadgeProgress::DEFINITIONS — keep both in sync.
  CRITERIA = {
    "first_session" => ->(u) { total_sessions(u) >= 1 },
    "streak_3"      => ->(u) { u.current_streak >= 3 },
    "streak_7"      => ->(u) { u.current_streak >= 7 },
    "streak_30"     => ->(u) { u.current_streak >= 30 },
    "streak_100"    => ->(u) { u.current_streak >= 100 },
    "cards_10"      => ->(u) { total_study_reviews(u) >= 10 },
    "cards_100"     => ->(u) { total_study_reviews(u) >= 100 },
    "cards_500"     => ->(u) { total_study_reviews(u) >= 500 },
    "cards_1000"    => ->(u) { total_study_reviews(u) >= 1000 },
    "perfect_test"  => ->(u) { perfect_test?(u) }
  }.freeze

  def self.call(user)
    earned_keys  = user.badges.pluck(:key).to_set
    all_badges   = Badge.all.index_by(&:key)
    newly_earned = []

    CRITERIA.each do |key, check|
      next if earned_keys.include?(key)
      next unless (badge = all_badges[key])
      next unless check.call(user)

      ApplicationRecord.transaction do
        user_badge = user.user_badges.create!(badge: badge, earned_at: Time.current)
        CreateNotification.call(recipient: user, event_type: "badge_earned", notifiable: user_badge)
        newly_earned << badge
      end
    end

    newly_earned
  end

  def self.total_sessions(user)
    user.study_sessions.completed.count +
      user.learn_sessions.completed.count +
      user.test_sessions.completed.count
  end

  # Learn/Test sessions use different metrics; only spaced-repetition Study sessions have cards_reviewed.
  def self.total_study_reviews(user)
    user.study_sessions.sum(:cards_reviewed)
  end

  def self.perfect_test?(user)
    user.test_sessions.completed.where("questions_total > 0 AND score = questions_total").exists?
  end
end
