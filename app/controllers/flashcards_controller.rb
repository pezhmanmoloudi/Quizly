class FlashcardsController < ApplicationController
  before_action :set_deck, only: [:new, :create]
  before_action :set_flashcard, only: [:edit, :update, :destroy]

  def new
    @flashcard = @deck.flashcards.build
  end

  def create
    @flashcard = @deck.flashcards.build(flashcard_params)
    if @flashcard.save
      redirect_to @deck, notice: "Card added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @flashcard.update(flashcard_params)
      redirect_to @flashcard.deck, notice: "Card updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    deck = @flashcard.deck
    @flashcard.destroy
    redirect_to deck, notice: "Card deleted."
  end

  private

  def set_deck
    @deck = Current.user.decks.find(params[:deck_id])
  end

  def set_flashcard
    @flashcard = Flashcard.joins(:deck).where(decks: { user: Current.user }).find(params[:id])
  end

  def flashcard_params
    params.require(:flashcard).permit(:front_content, :back_content, :position)
  end
end
