class DashboardController < ApplicationController
  def index
    @decks         = Current.user.decks.includes(:flashcards).order(created_at: :desc)
    @total_decks   = Current.user.decks.count
    @total_cards   = Flashcard.joins(:deck).where(decks: { user_id: Current.user.id }).count
    @popular_decks = Deck.public_decks.popular
                         .where.not(user: Current.user)
                         .includes(:user)
                         .limit(6)

    deck_ids = @decks.map(&:id)
    @due_counts = CardProgress.due
                              .unscope(:order)
                              .joins(:flashcard)
                              .where(user: Current.user, flashcards: { deck_id: deck_ids })
                              .group("flashcards.deck_id")
                              .count
  end
end
