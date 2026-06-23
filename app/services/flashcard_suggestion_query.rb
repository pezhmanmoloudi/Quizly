class FlashcardSuggestionQuery
  SCORES = {
    own_primary:    100,
    public_primary:  80,
    own_opposite:    60,
    public_opposite: 40
  }.freeze

  FETCH_LIMIT = 10

  def self.call(q:, field:, lang:, user:, limit: 3)
    new(q:, field:, lang:, user:, limit:).call
  end

  def initialize(q:, field:, lang:, user:, limit:)
    @q      = q.to_s.strip
    @field  = field.to_s
    @lang   = lang.to_s
    @user   = user
    @limit  = limit
  end

  def call
    return [] if @q.blank?

    candidates = fetch_own_primary +
                 fetch_public_primary +
                 fetch_own_opposite +
                 fetch_public_opposite

    deduplicate_and_rank(candidates)
  end

  private

  def primary_col  = @field == "back" ? "back_content"  : "front_content"
  def opposite_col = @field == "back" ? "front_content" : "back_content"
  def primary_lang = @field == "back" ? "back_language" : "front_language"

  def like_pattern
    @like_pattern ||= "#{Flashcard.sanitize_sql_like(@q)}%"
  end

  def own_base
    Flashcard.joins(:deck).where(decks: { user_id: @user.id })
  end

  def public_base
    Flashcard.joins(:deck)
             .where(public: true)
             .where.not(decks: { user_id: @user.id })
  end

  def fetch_own_primary
    scope = own_base
    scope = scope.where(primary_lang => @lang) if @lang.present?
    fetch(scope, primary_col, SCORES[:own_primary])
  end

  def fetch_public_primary
    scope = public_base
    scope = scope.where(primary_lang => @lang) if @lang.present?
    fetch(scope, primary_col, SCORES[:public_primary])
  end

  def fetch_own_opposite
    fetch(own_base, opposite_col, SCORES[:own_opposite])
  end

  def fetch_public_opposite
    fetch(public_base, opposite_col, SCORES[:public_opposite])
  end

  def fetch(scope, col, score)
    scope
      .where("LOWER(#{col}) LIKE LOWER(?)", like_pattern)
      .order(Arel.sql("LENGTH(#{col}) ASC"))
      .limit(FETCH_LIMIT)
      .pluck(col)
      .map { |word| { word: word, score: score } }
  end

  def deduplicate_and_rank(candidates)
    best = candidates.each_with_object({}) do |entry, acc|
      key = entry[:word].downcase
      acc[key] = entry if acc[key].nil? || entry[:score] > acc[key][:score]
    end

    best.values
        .sort_by { |e| [-e[:score], e[:word].length, e[:word]] }
        .first(@limit)
        .map { |e| e[:word] }
  end
end
