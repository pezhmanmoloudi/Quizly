class DashboardController < ApplicationController
  def index
    @decks       = Current.user.decks.includes(:flashcards).order(created_at: :desc)
    @total_decks = Current.user.decks.count
    @total_cards = Flashcard.joins(:deck).where(decks: { user_id: Current.user.id }).count
  end
end
