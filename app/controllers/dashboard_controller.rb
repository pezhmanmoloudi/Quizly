class DashboardController < ApplicationController
  def index
    @decks       = Current.user.decks.includes(:flashcards).order(created_at: :desc)
    @total_decks = Current.user.decks.count
    @total_cards = Flashcard.joins(:deck).where(decks: { user_id: Current.user.id }).count

    deck_ids    = @decks.map(&:id)
    @due_counts = CardProgress.due
                              .unscope(:order)
                              .joins(:flashcard)
                              .where(user: Current.user, flashcards: { deck_id: deck_ids })
                              .group("flashcards.deck_id")
                              .count
    @total_due  = @due_counts.values.sum

    @last_studied_dates = StudySession
                          .where(user: Current.user, deck_id: deck_ids)
                          .group(:deck_id)
                          .maximum(:started_at)

    if @due_counts.any?
      deck_ids_with_due = @due_counts.keys
      recent_activity = CardProgress
        .joins(:flashcard)
        .where(user: Current.user, flashcards: { deck_id: deck_ids_with_due })
        .where.not(last_reviewed_at: nil)
        .group("flashcards.deck_id")
        .maximum(:last_reviewed_at)
      best_id = if recent_activity.any?
        recent_activity.max_by { |_, v| v }.first
      else
        @due_counts.max_by { |_, v| v }.first
      end
      @continue_deck = @decks.find { |d| d.id == best_id }
      @continue_due  = @due_counts[best_id]
    end

    @badges_preview  = Badge.preview_for(Current.user)
    @badges_earned   = Current.user.user_badges.count
    @badges_total    = Badge.count
  end
end
