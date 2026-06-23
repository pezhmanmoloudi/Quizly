class SignalBuilder
  def self.call(q:, user:, field:, lang:)
    new(q:, user:, field:, lang:).call
  end

  def initialize(q:, user:, field:, lang:)
    @q     = q.to_s.strip
    @user  = user
    @field = field.to_s
    @lang  = lang.to_s
  end

  def call
    [].tap do |enriched|
      enriched.concat annotate(fetch_own_primary,     :own_primary)
      enriched.concat annotate(fetch_public_primary,  :public_primary)
      enriched.concat annotate(fetch_own_opposite,    :own_opposite)
      enriched.concat annotate(fetch_public_opposite, :public_opposite)
    end
  end

  private

  def primary_col   = @field == "back" ? "back_content"       : "front_content"
  def opposite_col  = @field == "back" ? "front_content"      : "back_content"
  def deck_lang_col = @field == "back" ? :definition_language : :term_language

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
    scope = scope.where(decks: { deck_lang_col => @lang }) if @lang.present?
    SuggestionEngine.call(q: @q, scope: scope, col: primary_col)
  end

  def fetch_public_primary
    scope = public_base
    scope = scope.where(decks: { deck_lang_col => @lang }) if @lang.present?
    SuggestionEngine.call(q: @q, scope: scope, col: primary_col)
  end

  def fetch_own_opposite
    SuggestionEngine.call(q: @q, scope: own_base, col: opposite_col)
  end

  def fetch_public_opposite
    SuggestionEngine.call(q: @q, scope: public_base, col: opposite_col)
  end

  def annotate(strings, source)
    strings.map { |value| { value: value, source: source } }
  end
end
