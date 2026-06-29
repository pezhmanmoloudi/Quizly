# Computes per-badge progress for the dashboard achievements carousel.
#
# Targets here mirror the thresholds embedded in BadgeAwarder::CRITERIA lambdas.
# Keep the two in sync — if a threshold changes there, update the matching target below.
class BadgeProgress
  Entry = Struct.new(:badge, :earned, :current, :target, :percent, keyword_init: true) do
    def earned? = earned
  end

  # badge key => { metric: ->(user) { Integer }, target: Integer }
  DEFINITIONS = {
    "first_session" => { metric: ->(u) { [ BadgeAwarder.total_sessions(u), 1 ].min },      target: 1 },
    "streak_3"      => { metric: ->(u) { u.current_streak },                                target: 3 },
    "streak_7"      => { metric: ->(u) { u.current_streak },                                target: 7 },
    "streak_30"     => { metric: ->(u) { u.current_streak },                                target: 30 },
    "streak_100"    => { metric: ->(u) { u.current_streak },                                target: 100 },
    "cards_10"      => { metric: ->(u) { BadgeAwarder.total_study_reviews(u) },             target: 10 },
    "cards_100"     => { metric: ->(u) { BadgeAwarder.total_study_reviews(u) },             target: 100 },
    "cards_500"     => { metric: ->(u) { BadgeAwarder.total_study_reviews(u) },             target: 500 },
    "cards_1000"    => { metric: ->(u) { BadgeAwarder.total_study_reviews(u) },             target: 1000 },
    "perfect_test"  => { metric: ->(u) { BadgeAwarder.perfect_test?(u) ? 1 : 0 },           target: 1 }
  }.freeze

  # Fixed set of badges surfaced on the dashboard, in display order.
  # The full set lives on the achievements page (achievements_path).
  DASHBOARD_KEYS = %w[perfect_test cards_10 cards_100 streak_7].freeze

  # Returns one entry per DASHBOARD_KEY (in order), skipping any key without a
  # seeded badge. Used for the static dashboard achievements grid.
  def self.preview_for(user)
    earned_at_by_id = user.user_badges.pluck(:badge_id, :earned_at).to_h
    badges_by_key   = Badge.where(key: DASHBOARD_KEYS).index_by(&:key)

    DASHBOARD_KEYS.filter_map do |key|
      badge = badges_by_key[key]
      build_entry(badge, user, earned_at_by_id) if badge
    end
  end

  def self.build_entry(badge, user, earned_at_by_id)
    definition = DEFINITIONS[badge.key]
    target     = definition&.fetch(:target) || 1
    earned     = earned_at_by_id.key?(badge.id)
    current    = earned ? target : (definition ? definition[:metric].call(user).to_i.clamp(0, target) : 0)
    percent    = target.positive? ? (current * 100.0 / target).round.clamp(0, 100) : 0

    Entry.new(badge: badge, earned: earned, current: current, target: target, percent: percent)
  end
end
