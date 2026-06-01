class DecksController < ApplicationController
  before_action :require_authentication
  before_action :set_deck, only: [:show, :edit, :update, :destroy, :study]

  def index
    @decks = Current.user.decks.order(created_at: :desc)
  end

  def show
  end

  def new
    @deck = Current.user.decks.build
  end

  def create
    @deck = Current.user.decks.build(deck_params)
    if @deck.save
      redirect_to @deck, notice: "Deck created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @deck.update(deck_params)
      redirect_to @deck, notice: "Deck updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deck.destroy
    redirect_to decks_path, notice: "Deck deleted."
  end

  def study
    CardProgress.initialize_for_deck(@deck, Current.user)
    @card_progress = Current.user.card_progresses
                                  .due
                                  .joins(:flashcard)
                                  .where(flashcards: { deck_id: @deck.id })
                                  .includes(:flashcard)
                                  .first
  end

  private

  def set_deck
    @deck = Current.user.decks.find(params[:id])
  end

  def deck_params
    params.require(:deck).permit(:title, :description)
  end
end
