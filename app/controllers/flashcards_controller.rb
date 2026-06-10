class FlashcardsController < ApplicationController
  before_action :set_deck, only: [:new, :create]
  before_action :set_flashcard, only: [:edit, :update, :destroy]
  before_action :set_soft_deleted_flashcard, only: [:restore]

  def new
  end

  def create
    @flashcard = @deck.flashcards.build(flashcard_params)
    if @flashcard.save
      respond_to do |format|
        format.html { redirect_to @deck, notice: t("flashcards.created") }
        format.json { render json: { id: @flashcard.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @flashcard.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @flashcard.update(flashcard_params)
      respond_to do |format|
        format.html { redirect_to @flashcard.deck, notice: t("flashcards.updated") }
        format.json { render json: { id: @flashcard.id }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @flashcard.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @deck = @flashcard.deck
    @flashcard.soft_delete!
    HardDeleteFlashcardJob.set(wait: 30.seconds).perform_later(@flashcard.id)

    respond_to do |format|
      format.turbo_stream { render :destroy }
      format.html do
        items        = params[:items].to_i.positive? ? params[:items].to_i : 10
        current_page = [params[:page].to_i, 1].max
        total        = @deck.flashcards.count
        last_page    = [(total.to_f / items).ceil, 1].max
        safe_page    = [current_page, last_page].min
        redirect_to deck_path(@deck, page: safe_page, items: items), notice: t("flashcards.deleted")
      end
    end
  end

  def restore
    @deck = @flashcard.deck
    @flashcard.restore!

    respond_to do |format|
      format.turbo_stream do
        flash[:notice] = t("flashcards.restored")
        render turbo_stream: turbo_stream.refresh
      end
      format.html { redirect_to deck_path(@deck), notice: t("flashcards.restored") }
    end
  end

  private

  def set_deck
    @deck = Current.user.decks.find(params[:deck_id])
  end

  def set_flashcard
    @flashcard = Flashcard.joins(:deck).where(decks: { user: Current.user }).find(params[:id])
  end

  def set_soft_deleted_flashcard
    @flashcard = Flashcard.unscoped
      .joins(:deck)
      .where(decks: { user: Current.user })
      .where.not(deleted_at: nil)
      .find(params[:id])
  end

  def flashcard_params
    params.require(:flashcard).permit(:front_content, :back_content, :position,
                                      :front_language, :back_language, :image)
  end
end
