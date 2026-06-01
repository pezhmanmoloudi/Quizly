class DashboardController < ApplicationController
  def index
    @recent_decks = Current.user.decks.order(created_at: :desc).limit(4)
    @total_decks  = Current.user.decks.count
    @total_cards  = Current.user.decks.joins(:flashcards).count
  end
end
