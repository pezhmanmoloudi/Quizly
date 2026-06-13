class DecksController < ApplicationController
  allow_unauthenticated_access only: [:show, :flashcard, :match, :unlock, :authenticate]
  before_action :set_owned_deck,        only: [:edit, :update, :destroy, :rotate_share_token]
  before_action :set_content_deck,      only: [:cards, :update_cards]
  before_action :set_accessible_deck,   only: [:show, :study, :flashcard, :match, :fork, :learn, :test]
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
    @deck.share_token = SecureRandom.urlsafe_base64(32)
  end

  def create
    @deck = Current.user.decks.build(deck_create_params)
    if @deck.save
      redirect_to cards_deck_path(@deck), notice: t("decks.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @deck.update(deck_update_params)
      redirect_to @deck, notice: t("decks.updated")
    else
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

  def cards
    @existing   = @deck.flashcards.to_a
    @draft_rows = []
    @imported   = false
  end

  def update_cards
    row_data = (params.dig(:deck, :flashcards_attributes) || {}).values
                 .reject { |r| r[:front_content].blank? && r[:back_content].blank? && r[:_destroy] != "1" }
                 .map { |r| r.permit(:front_content, :back_content, :front_language, :back_language).to_h.symbolize_keys }

    form = CardEditorForm.new(
      rows:              row_data,
      requires_language: params[:requires_language] == "true"
    )

    unless form.valid?
      flash.now[:alert] = form.errors.full_messages.first
      @existing   = @deck.flashcards.to_a
      @draft_rows = []
      @imported   = params[:requires_language] != "true"
      return render :cards, status: :unprocessable_entity
    end

    if row_data.empty? && @deck.flashcards.none?
      flash.now[:alert] = t("decks.cards.error_no_cards")
      @existing   = @deck.flashcards.to_a
      @draft_rows = []
      @imported   = params[:requires_language] != "true"
      return render :cards, status: :unprocessable_entity
    end

    if @deck.update(cards_params)
      redirect_to @deck, notice: t("decks.cards_saved")
    else
      @existing   = @deck.flashcards.to_a
      @draft_rows = []
      @imported   = params[:requires_language] != "true"
      render :cards, status: :unprocessable_entity
    end
  end

  def fork
    raise ActiveRecord::RecordNotFound unless @deck.can_fork?(Current.user)

    fork_name = params.dig(:deck, :name).presence || @deck.name
    fork_vis   = Deck::FORKABLE_VISIBILITIES.include?(params.dig(:deck, :visibility)) \
                   ? params.dig(:deck, :visibility) : "private"

    ActiveRecord::Base.transaction do
      @fork = Deck.create!(
        user:                               Current.user,
        name:                               fork_name,
        description:                        @deck.description,
        subject_tags:                       @deck.subject_tags,
        language_code:                      @deck.language_code,
        edit_permission:                    "owner_only",
        visibility:                         fork_vis,
        forked_from:                        @deck,
        forked_from_title_snapshot:         @deck.name,
        forked_from_owner_display_snapshot: @deck.user.display_name,
        forked_at:                          Time.current
      )
      @deck.flashcards.each do |card|
        @fork.flashcards.create!(
          front_content: card.front_content,
          back_content:  card.back_content,
          position:      card.position
        )
      end
      @deck.increment!(:forks_count)
    end

    redirect_to edit_deck_path(@fork), notice: t("decks.forked")
  rescue ActiveRecord::RecordNotFound
    redirect_to explore_path, alert: t("decks.not_available")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to deck_path(@deck), alert: e.record.errors.full_messages.first
  end

  def unlock
    @deck = Deck.find(params[:id])
    if @deck.can_view?(Current.user, session_auth: deck_session_auth(@deck), share_auth: deck_share_auth(@deck))
      redirect_to @deck
    end
  end

  def rotate_share_token
    @deck.update!(share_token: SecureRandom.urlsafe_base64(32))
    redirect_to edit_deck_path(@deck), notice: t("decks.share_token_rotated")
  end

  def authenticate
    @deck = Deck.find(params[:id])
    if @deck.authenticate_access_password(params[:access_password].to_s)
      session["deck_auth_#{@deck.id}"] = true
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

  def set_content_deck
    deck = Deck.find(params[:id])
    raise ActiveRecord::RecordNotFound unless deck.can_edit?(Current.user, session_auth: deck_session_auth(deck))
    @deck = deck
  end

  def set_accessible_deck
    deck = Deck.find(params[:id])
    if deck.can_view?(Current.user, session_auth: deck_session_auth(deck), share_auth: deck_share_auth(deck))
      @deck = deck
    elsif deck.password_protected? && action_name == "show"
      @deck = deck
      @locked = true
    elsif deck.password_protected?
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

  def deck_create_params
    params.require(:deck).permit(
      :name, :description, :language_code, :visibility, :tag_list,
      :edit_permission, :access_password, :access_password_confirmation,
      :share_token
    )
  end

  def deck_update_params
    params.require(:deck).permit(
      :name, :description, :language_code, :visibility, :tag_list,
      :edit_permission, :access_password, :access_password_confirmation
    )
  end

  def set_noindex_for_unlisted
    response.headers["X-Robots-Tag"] = "noindex" if @deck&.unlisted?
  end

  def cards_params
    params.require(:deck).permit(
      flashcards_attributes: [:id, :front_content, :back_content, :position,
                               :front_language, :back_language, :image, :_destroy]
    )
  end
end
