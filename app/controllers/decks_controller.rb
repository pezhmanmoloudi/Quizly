class DecksController < ApplicationController
  include DeckScoped

  allow_unauthenticated_access only: [ :show, :flashcard, :match ]

  before_action :set_deck,                 only: [ :show, :flashcard, :match,
                                                    :edit, :update, :destroy, :update_visibility ]
  before_action :resolve_access,           only: [ :show, :flashcard, :match ]
  before_action :set_noindex_for_unlisted, only: [ :show, :flashcard, :match ]

  DECK_INDEX_PER_PAGE    = 12
  ITEMS_PER_PAGE_OPTIONS = [ 5, 10, 15, 20, 30 ].freeze

  def index
    @sort  = params[:sort].in?(%w[az most_due]) ? params[:sort] : "recent"
    order  = @sort == "az" ? { name: :asc } : { created_at: :desc }

    @query = params[:q].presence
    decks_scope = Current.user.decks.includes(:flashcards).order(order)
    decks_scope = decks_scope.search(@query) if @query
    all_deck_ids = decks_scope.map(&:id)

    @due_counts = CardProgress.due
                              .unscope(:order)
                              .joins(:flashcard)
                              .where(user: Current.user, flashcards: { deck_id: all_deck_ids })
                              .group("flashcards.deck_id")
                              .count

    @last_studied_dates = StudySession
                          .where(user: Current.user, deck_id: all_deck_ids)
                          .group(:deck_id)
                          .maximum(:started_at)

    if @sort == "most_due"
      sorted = decks_scope.sort_by { |d| -(@due_counts[d.id] || 0) }
      @pagy, @decks = pagy(sorted, limit: DECK_INDEX_PER_PAGE)
    else
      @pagy, @decks = pagy(decks_scope, limit: DECK_INDEX_PER_PAGE)
    end
  end

  def show
    @pagy, @flashcards = pagy(@deck.flashcards.order(:position), limit: items_per_page)
    @items_per_page = items_per_page
    if authenticated?
      @is_saved = DeckFolder.joins(:folder)
                            .where(deck_id: @deck.id, folders: { user_id: Current.user.id })
                            .exists?
    end
  end

  def create
    @deck = Decks::CreationService.call(user: Current.user, name: t("decks.default_name"))
    redirect_to edit_deck_path(@deck)
  rescue ActiveRecord::RecordInvalid
    redirect_to root_path, alert: t("decks.create_failed")
  end

  def edit
    authorize @deck, :update?
    @flashcards = @deck.flashcards.order(:position)
  end

  def update
    authorize @deck
    if @deck.update(deck_update_params)
      redirect_to @deck, notice: t("decks.updated")
    else
      @flashcards = @deck.flashcards.order(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @deck
    from_page = [ params[:from_page].to_i, 1 ].max
    @deck.destroy

    remaining = Current.user.decks.count
    last_page = [ (remaining.to_f / DECK_INDEX_PER_PAGE).ceil, 1 ].max
    safe_page = [ from_page, last_page ].min

    respond_to do |format|
      format.turbo_stream { redirect_to decks_path(page: safe_page), notice: t("decks.deleted") }
      format.html         { redirect_to decks_path(page: safe_page), notice: t("decks.deleted") }
    end
  end

  # TODO: belongs in a future DeckSettingsController (settings/access-management domain)
  def update_visibility
    authorize @deck, :manage_access?
    if @deck.update(manage_access_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @deck }
      end
    else
      @deck.restore_attributes
      respond_to do |format|
        format.turbo_stream { render :update_visibility, status: :unprocessable_entity }
        format.html { redirect_to deck_path(@deck), alert: @deck.errors.full_messages.to_sentence }
      end
    end
  end

  def flashcard
    @flashcards   = @deck.flashcards
    @study_mode   = params[:mode] == "study"
    if @access.owner?
      # TODO: CardProgress.initialize_for_deck is a future extraction candidate (e.g., a StudyContext concern)
      CardProgress.initialize_for_deck(@deck, Current.user)
      progresses       = Current.user.card_progresses.where(flashcard_id: @flashcards.map(&:id))
      @card_progresses = progresses.index_by(&:flashcard_id)
      @card_progresses_json = progresses.map { |cp|
        {
          id:               cp.id,
          flashcard_id:     cp.flashcard_id,
          ease_factor:      cp.ease_factor,
          interval:         cp.interval,
          repetitions:      cp.repetitions,
          next_review_at:   cp.next_review_at&.iso8601,
          last_reviewed_at: cp.last_reviewed_at&.iso8601
        }
      }.to_json
    end
  end

  def match
    @cards = @deck.flashcards.limit(16).to_a.shuffle
  end

  private

  def items_per_page
    ITEMS_PER_PAGE_OPTIONS.include?(params[:items].to_i) ? params[:items].to_i : 10
  end

  def manage_access_params
    raw = params.require(:deck).permit(:visibility, :access_mode, :password, :password_confirmation)
    result = {}
    vis = raw[:visibility].to_s
    result[:visibility] = vis if Deck::VISIBILITY_VALUES.include?(vis)
    am = raw[:access_mode].to_s
    result[:access_mode] = am if Deck::ACCESS_MODE_VALUES.include?(am)
    if result[:access_mode] == "password" && raw[:password].present?
      result[:password]              = raw[:password]
      result[:password_confirmation] = raw[:password_confirmation]
    end
    result
  end

  def deck_update_params
    params.require(:deck).permit(
      :name, :description, :language_code, :term_language, :definition_language,
      :visibility, :tag_list,
      :access_mode, :password, :password_confirmation
    )
  end
end
