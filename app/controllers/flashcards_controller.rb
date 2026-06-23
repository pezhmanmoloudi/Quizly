class FlashcardsController < ApplicationController
  before_action :set_deck,                   only: [ :create ]
  before_action :set_flashcard,              only: [ :update, :destroy, :purge_image ]
  before_action :set_soft_deleted_flashcard, only: [ :restore ]

  # Sidebar queries are irrelevant for this lightweight turbo-frame action
  skip_before_action :load_sidebar_decks,   only: [ :suggest ]
  skip_before_action :load_sidebar_folders, only: [ :suggest ]

  def suggest
    suggestions = FlashcardSuggestionQuery.call(
      q:     params[:q].to_s.strip,
      field: params[:field].to_s,
      lang:  params[:lang].to_s,
      user:  Current.user
    )

    render partial: "flashcards/suggestions",
           locals: { suggestions: suggestions, query: params[:q].to_s.strip }
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
        format.html { redirect_to edit_deck_path(@deck), alert: @flashcard.errors.full_messages.first }
        format.json { render json: { errors: @flashcard.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @flashcard.update(flashcard_params)
      respond_to do |format|
        format.html { redirect_to @flashcard.deck, notice: t("flashcards.updated") }
        format.json { render json: { id: @flashcard.id }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_deck_path(@flashcard.deck), alert: @flashcard.errors.full_messages.first }
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
        current_page = [ params[:page].to_i, 1 ].max
        total        = @deck.flashcards.count
        last_page    = [ (total.to_f / items).ceil, 1 ].max
        safe_page    = [ current_page, last_page ].min
        redirect_to deck_path(@deck, page: safe_page, items: items), notice: t("flashcards.deleted")
      end
    end
  end

  def purge_image
    @flashcard.image.purge
    respond_to do |format|
      format.json { render json: { id: @flashcard.id }, status: :ok }
    end
  end

  def restore
    @deck = @flashcard.deck
    @next_card = @deck.flashcards.where("position > ?", @flashcard.position).order(:position).first
    @flashcard.restore!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to deck_path(@deck), notice: t("flashcards.restored") }
    end
  end

  private

  def set_deck
    @deck = Deck.find(params[:deck_id])
    authorize @deck, :manage_flashcards?
  end

  def set_flashcard
    @flashcard = Flashcard.find(params[:id])
    authorize @flashcard
  end

  def set_soft_deleted_flashcard
    @flashcard = Flashcard.unscoped.where.not(deleted_at: nil).find(params[:id])
    authorize @flashcard, :restore?
  end

  def flashcard_params
    params.require(:flashcard).permit(:front_content, :back_content, :position,
                                      :front_language, :back_language, :image)
  end
end
