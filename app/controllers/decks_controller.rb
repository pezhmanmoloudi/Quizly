class DecksController < ApplicationController
  allow_unauthenticated_access only: [:show, :flashcard, :match]
  before_action :set_deck, only: [:edit, :update, :destroy, :cards, :update_cards]
  before_action :set_accessible_deck, only: [:show, :study, :flashcard, :match, :fork, :learn, :test]

  DECK_INDEX_PER_PAGE   = 12
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
      @pagy, @decks = pagy_array(sorted, limit: DECK_INDEX_PER_PAGE)
    else
      @pagy, @decks = pagy(decks_scope, limit: DECK_INDEX_PER_PAGE)
    end
  end

  def show
    items = ITEMS_PER_PAGE_OPTIONS.include?(params[:items].to_i) ? params[:items].to_i : 10
    @pagy, @flashcards = pagy(@deck.flashcards.order(:position), limit: items)
    @items_per_page = items
  end

  def new
    @deck = Current.user.decks.build
  end

  def create
    @deck = Current.user.decks.build(deck_params)
    if @deck.save
      redirect_to cards_deck_path(@deck), notice: "Deck created."
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
    from_page = [params[:from_page].to_i, 1].max
    @deck.destroy

    remaining = Current.user.decks.count
    last_page = [(remaining.to_f / DECK_INDEX_PER_PAGE).ceil, 1].max
    safe_page = [from_page, last_page].min

    respond_to do |format|
      format.turbo_stream { redirect_to decks_path(page: safe_page), notice: "Deck deleted." }
      format.html         { redirect_to decks_path(page: safe_page), notice: "Deck deleted." }
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
    else
      session.delete(:study_session_id)
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
    @cards = @deck.flashcards.limit(8).to_a.shuffle
  end

  def learn
    flashcards = @deck.flashcards.to_a
    if flashcards.empty?
      @learn_session = nil
      @current_item  = nil
      return
    end

    # turbo_action=replace means "restart" — clear any active session
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

    # turbo_action=replace means "restart" — clear any active session
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
    @initial_rows = 1
  end

  def update_cards
    if @deck.update(cards_params)
      redirect_to @deck, notice: "Cards saved."
    else
      render :cards, status: :unprocessable_entity
    end
  end

  def fork
    raise ActiveRecord::RecordNotFound unless @deck.public?

    ActiveRecord::Base.transaction do
      copy = Deck.create!(
        user: Current.user,
        name: "#{@deck.name} (copy)",
        description: @deck.description,
        language_code: @deck.language_code,
        visibility: "private",
        forked_from: @deck
      )
      @deck.flashcards.each do |card|
        copy.flashcards.create!(
          front_content: card.front_content,
          back_content: card.back_content,
          position: card.position
        )
      end
      @deck.increment!(:forks_count)
    end

    redirect_to decks_path, notice: "Deck added to your library."
  rescue ActiveRecord::RecordNotFound
    redirect_to explore_path, alert: "Deck not available."
  end

  private

  def set_deck
    @deck = Current.user.decks.find(params[:id])
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

  def set_accessible_deck
    deck = Deck.find(params[:id])
    unless deck.user == Current.user || deck.public?
      raise ActiveRecord::RecordNotFound
    end
    @deck = deck
  end

  def deck_params
    params.require(:deck).permit(:name, :description, :language_code, :visibility, :tag_list)
  end

  def cards_params
    params.require(:deck).permit(
      flashcards_attributes: [:id, :front_content, :back_content, :position, :_destroy]
    )
  end
end
