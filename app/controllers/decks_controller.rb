class DecksController < ApplicationController
  allow_unauthenticated_access only: [ :show, :flashcard, :match, :unlock ]

  before_action :set_deck,       only: [ :show, :flashcard, :match, :fork, :copy,
                                          :learn, :test, :study,
                                          :edit, :update, :destroy, :update_visibility, :unlock ]
  before_action :resolve_access, only: [ :show, :flashcard, :match, :study, :learn, :test ]
  before_action :set_noindex_for_unlisted, only: [ :show, :study, :flashcard, :match, :learn, :test ]

  DECK_INDEX_PER_PAGE    = 12
  ITEMS_PER_PAGE_OPTIONS = [ 5, 10, 15, 20, 30 ].freeze

  def index
    @sort  = params[:sort].in?(%w[az most_due]) ? params[:sort] : "recent"
    order  = @sort == "az" ? { name: :asc } : { created_at: :desc }

    decks_scope = Current.user.decks.includes(:flashcards).order(order)

    @due_counts = CardProgress.due
                              .unscope(:order)
                              .joins(:flashcard)
                              .where(user: Current.user, flashcards: { deck_id: decks_scope.map(&:id) })
                              .group("flashcards.deck_id")
                              .count

    if @sort == "most_due"
      sorted = decks_scope.sort_by { |d| -(@due_counts[d.id] || 0) }
      @pagy, @decks = pagy(sorted, limit: DECK_INDEX_PER_PAGE)
    else
      @pagy, @decks = pagy(decks_scope, limit: DECK_INDEX_PER_PAGE)
    end

    @saved_decks = Current.user.saved_decks
                               .merge(Deck.complete)
                               .includes(:user, :flashcards)
                               .order("library_items.created_at DESC")
  end

  def show
    @pagy, @flashcards = pagy(@deck.flashcards.order(:position), limit: items_per_page)
    @items_per_page = items_per_page
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

  def study
    CardProgress.initialize_for_deck(@deck, Current.user)

    @study_mode = params[:mode] == "starred" ? "starred" : "all"

    due_scope = Current.user.card_progresses
                            .due
                            .joins(:flashcard)
                            .where(flashcards: { deck_id: @deck.id })
    due_scope = due_scope.starred if @study_mode == "starred"

    @cards_remaining = due_scope.unscope(:order).count
    @card_progress   = due_scope.includes(:flashcard).first

    if @card_progress.present?
      @study_session = Decks::StudySessionService.find_or_create(
        deck:       @deck,
        user:       Current.user,
        session_id: session[:study_session_id],
        due_count:  @cards_remaining
      )
      session[:study_session_id] = @study_session.id
      @cards_total = @study_session.cards_total
      @cards_done  = @cards_total - @cards_remaining
      @streak      = session[:study_streak].to_i
    else
      session.delete(:study_session_id)
      session.delete(:study_streak)
    end
  end

  def flashcard
    @flashcards = @deck.flashcards
    if @access.owner?
      CardProgress.initialize_for_deck(@deck, Current.user)
      @card_progresses = Current.user.card_progresses
                                     .where(flashcard_id: @flashcards.map(&:id))
                                     .index_by(&:flashcard_id)
    end
  end

  def match
    @cards = @deck.flashcards.limit(16).to_a.shuffle
  end

  def learn
    flashcards = @deck.flashcards.to_a
    if flashcards.empty?
      @learn_session = nil
      @current_item  = nil
      return
    end

    if params[:turbo_action] == "replace" || params[:restart]
      session.delete(:learn_session_id)
    end

    @learn_session = Decks::LearnSessionService.find_or_create(
      deck:       @deck,
      user:       Current.user,
      session_id: session[:learn_session_id]
    )
    session[:learn_session_id] = @learn_session.id
    @current_item = @learn_session.next_item

    if @current_item.nil? && !@learn_session.finished?
      @learn_session.update!(finished_at: Time.current)
    end
  end

  def test
    flashcards = @deck.flashcards.to_a
    if flashcards.empty?
      @test_session = nil
      return
    end

    if params[:turbo_action] == "replace" || params[:restart]
      session.delete(:test_session_id)
    end

    @test_session = Decks::TestSessionService.find_or_create(
      deck:       @deck,
      user:       Current.user,
      session_id: session[:test_session_id],
      flashcards: flashcards
    )
    session[:test_session_id] = @test_session.id

    if @test_session.finished?
      @test_session = nil
    end
  end

  def fork
    authorize @deck, :save_to_library?
    perform_library_save
  rescue Pundit::NotAuthorizedError
    destination = policy(@deck).show? ? deck_path(@deck) : fallback_destination
    redirect_to destination
  end

  def copy
    authorize @deck, :copy?
    copied = Decks::ForkService.call(
      source_deck: @deck,
      user:        Current.user,
      name:        t("decks.action.copy_name", name: @deck.name)
    )
    redirect_to deck_path(copied), notice: t("decks.action.copied")
  rescue Pundit::NotAuthorizedError
    destination = policy(@deck).update? ? explore_path : fallback_destination
    redirect_to destination, alert: t("decks.not_available")
  end

  def unsave
    deck = Deck.find_by(id: params[:id])
    item = deck ? Current.user.library_items.find_by(deck: deck) : nil
    if item
      @deck = deck
      item.destroy
      @no_saved_decks = Current.user.library_items.none?
      flash.now[:notice] = t("decks.action.unsaved")
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to deck_path(@deck), notice: t("decks.action.unsaved") }
      end
    else
      redirect_to(deck ? deck_path(deck) : decks_path, alert: t("decks.action.not_in_library"))
    end
  end

  def unlock
    @access = Decks::AccessService.evaluate(deck: @deck, user: Current.user, session: session)

    if request.get? && !@access.locked?
      return redirect_to @deck
    end

    return unless request.post?

    result = Decks::AccessService.call(
      deck:     @deck,
      password: params[:password].to_s,
      session:  session
    )

    if result.ok?
      redirect_to @deck, notice: t("decks.unlock.success")
    else
      flash.now[:alert] = t("decks.unlock.invalid_password")
      render :unlock, status: :unprocessable_entity
    end
  end

  private

  def set_deck
    @deck = Deck.find(params[:id])
  end

  def resolve_access
    authorize @deck, :show?
    @access = Decks::AccessService.evaluate(deck: @deck, user: Current.user, session: session)
    redirect_to unlock_deck_path(@deck) if @access.locked?
  end

  def items_per_page
    ITEMS_PER_PAGE_OPTIONS.include?(params[:items].to_i) ? params[:items].to_i : 10
  end

  def perform_library_save
    LibraryItem.create!(user: Current.user, deck: @deck)
    flash.now[:notice] = t("decks.action.saved")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to deck_path(@deck), notice: t("decks.action.saved") }
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    flash.now[:notice] = t("decks.action.already_saved")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to deck_path(@deck), notice: t("decks.action.already_saved") }
    end
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
      :name, :description, :language_code, :visibility, :tag_list,
      :access_mode, :password, :password_confirmation
    )
  end

  def set_noindex_for_unlisted
    response.headers["X-Robots-Tag"] = "noindex" if @deck&.unlisted?
  end
end
