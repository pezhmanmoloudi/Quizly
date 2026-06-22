module Follows
  class DeckPublishedNotificationJob < ApplicationJob
    queue_as :default

    # MVP safety valve: skip fan-out for accounts with very large follower counts.
    # Prevents a single deck publish from generating tens of thousands of DB inserts
    # in a single job run. Configurable via ENV for easy tuning in production.
    MAX_FOLLOWERS = ENV.fetch("FANOUT_MAX_FOLLOWERS", 5_000).to_i

    def perform(deck_id)
      deck = Deck.find_by(id: deck_id)
      return if deck.nil?
      return unless deck.public? # Guard: visibility may have changed between enqueue and run

      deck_owner = deck.user
      return if deck_owner.followers_count > MAX_FOLLOWERS

      deck_owner.followers
                .joins(:notification_preference)
                .where(notification_preferences: { in_app_following_activity: true })
                .find_each do |follower|
        CreateNotification.call(
          recipient:  follower,
          event_type: "followed_user_published_deck",
          actor:      deck_owner,
          notifiable: deck
        )
      end
    end
  end
end
