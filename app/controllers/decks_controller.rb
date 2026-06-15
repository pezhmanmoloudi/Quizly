class DecksController < ApplicationController
  allow_unauthenticated_access only: [:show, :flashcard, :match, :unlock]
  before_action :set_owned_deck,          only: [:edit, :update, :destroy, :update_visibility]
  before_action :set_accessible_deck,     only: [:show, :study, :flashcard, :match, :fork, :copy, :learn, :test]
  before_action :set_noindex_for_unlisted, only: [:show, :study, :flashcard, :match, :learn, :test]

  DECK_INDEX_PER_PAGE    = 12
  ITEMS_PER_PAGE_OPTIONS = [5, 10, 15, 20, 30].freeze

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
                               .includes(:user, :flashcards)
                               .order("library_items.created_at DESC")
  end

  def show
    if @locked
      @sample_flashcards = @deck.flashcards.order(:position).limit(3)
      @locked_cards_count = @deck.flashcards.count
      return
    end
    items = ITEMS_PER_PAGE_OPTIONS.include?(params[:items].to_i) ? params[:items].to_i : 10
    @pagy, @flashcards = pagy(@deck.flashcards.order(:position), limit: items)
    @items_per_page = items
  end

  def new
    @deck = Current.user.decks.build
  end

  def create
    @deck = Current.user.decks.build(deck_create_params)
    if @deck.save
      redirect_to edit_deck_path(@deck), notice: t("decks.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @flashcards = @deck.flashcards.order(:position)
  end

  def update
    if @deck.update(deck_update_params)
      redirect_to @deck, notice: t("decks.updated")
    else
      @flashcards = @deck.flashcards.order(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    from_page = [params[:from_page].to_i, 1].max
    @deck.destroy

    remaining = Current.user.decks.count
    last_page = [(remaining.to_f / DECK_INDEX_PER_PAGE).ceil, 1].max
    safe_page = [from_page, last_page].min

    respond_to do |format|
      format.turbo_stream { redirect_to decks_path(page: safe_page), notice: t("decks.deleted") }
      format.html         { redirect_to decks_path(page: safe_page), notice: t("decks.deleted") }
    end
  end

  def update_visibility
    @deck.update(manage_access_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @deck }
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
      @study_session = find_or_create_study_session(@cards_remaining)
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
    if authenticated? && @deck.user == Current.user
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

    @learn_session = find_or_create_learn_session
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

    @test_session = find_or_create_test_session(flashcards)
    session[:test_session_id] = @test_session.id

    if @test_session.finished?
      @test_session = nil
    end
  end

  def fork
    return redirect_to deck_path(@deck) if @deck.can_delete?(Current.user)
    raise ActiveRecord::RecordNotFound unless @deck.can_save?(Current.user)
    perform_library_save
  rescue ActiveRecord::RecordNotFound
    redirect_to explore_path, alert: t("decks.not_available")
  end

  def copy
    raise ActiveRecord::RecordNotFound unless @deck.can_copy?(Current.user)
    copied = DeckDuplicator.call(
      source_deck: @deck,
      user:        Current.user,
      name:        t("decks.action.copy_name", name: @deck.name),
      visibility:  "private"
    )
    redirect_to deck_path(copied), notice: t("decks.action.copied")
  rescue ActiveRecord::RecordNotFound
    redirect_to explore_path, alert: t("decks.not_available")
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
    @deck = Deck.find(params[:id])
    @deck.unlocked = deck_unlocked?(@deck)
    if request.get? && (@deck.unlocked? || Current.user == @deck.user)
      return redirect_to @deck
    end
    return unless request.post?
    if @deck.authenticate_password(params[:password].to_s)
      session["deck_#{@deck.id}_unlocked"] = true
      redirect_to @deck, notice: t("decks.unlock.success")
    else
      flash.now[:alert] = t("decks.unlock.invalid_password")
      render :unlock, status: :unprocessable_entity
    end
  end

  private

  def set_owned_deck
    deck = Deck.find(params[:id])
    raise ActiveRecord::RecordNotFound unless deck.can_edit_settings?(Current.user)
    @deck = deck
  end

  def set_accessible_deck
    deck = Deck.find(params[:id])
    deck.unlocked = deck_unlocked?(deck)
    if deck.can_view?(Current.user)
      @deck = deck
    elsif deck.unlisted? && deck.password_digest.present? && action_name == "show"
      return redirect_to explore_path unless Current.user
      @deck = deck
      @locked = true
    elsif deck.unlisted? && deck.password_digest.present?
      redirect_to unlock_deck_path(deck) and return
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def find_or_create_learn_session
    sid = session[:learn_session_id]
    if sid
      existing = Current.user.learn_sessions.find_by(id: sid, finished_at: nil, deck: @deck)
      return existing if existing
    end
    ls = LearnSession.build_for(deck: @deck, user: Current.user)
    ls.save!
    ls
  end

  def find_or_create_test_session(flashcards)
    sid = session[:test_session_id]
    if sid
      existing = Current.user.test_sessions.find_by(id: sid, finished_at: nil, deck: @deck)
      return existing if existing
    end
    count = [ flashcards.size, 20 ].min
    questions = QuestionEngine.generate(flashcards: flashcards, count: count)
    Current.user.test_sessions.create!(
      deck: @deck,
      questions_data: questions.to_json,
      questions_total: questions.size,
      started_at: Time.current
    )
  end

  def find_or_create_study_session(due_count)
    sid = session[:study_session_id]
    if sid
      existing = Current.user.study_sessions.find_by(id: sid, finished_at: nil, deck: @deck)
      if existing
        existing.update_columns(cards_total: due_count) if due_count > existing.cards_total
        return existing
      end
    end
    Current.user.study_sessions.create!(deck: @deck, cards_total: due_count, started_at: Time.current)
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
    raw = params.require(:deck).permit(:visibility, :edit_permission, :password, :password_confirmation)
    result = {}
    vis = raw[:visibility].to_s
    result[:visibility] = vis if Deck::VISIBILITY_VALUES.include?(vis)
    ep = raw[:edit_permission].to_s
    result[:edit_permission] = ep if Deck::EDIT_PERMISSION_VALUES.include?(ep)
    result[:password] = raw[:password] if raw[:password].present?
    result[:password_confirmation] = raw[:password_confirmation] if raw[:password].present?
    result
  end

  def deck_create_params
    params.require(:deck).permit(
      :name, :description, :language_code, :visibility, :tag_list,
      :edit_permission, :password, :password_confirmation
    )
  end

  def deck_update_params
    params.require(:deck).permit(
      :name, :description, :language_code, :visibility, :tag_list,
      :edit_permission, :password, :password_confirmation
    )
  end

  def set_noindex_for_unlisted
    response.headers["X-Robots-Tag"] = "noindex" if @deck&.unlisted?
  end
end
