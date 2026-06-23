class FlashcardSuggestionQuery
  SCORES = {
    own_primary:    100,
    public_primary:  80,
    own_opposite:    60,
    public_opposite: 40
  }.freeze

  def self.call(q:, field:, lang:, user:, limit: 3)
    new(q:, field:, lang:, user:, limit:).call
  end

  def initialize(q:, field:, lang:, user:, limit:)
    @q     = q.to_s.strip
    @field = field.to_s
    @lang  = lang.to_s
    @user  = user
    @limit = limit
  end

  def call
    return [] if @q.blank?

    candidates = SignalBuilder.call(q: @q, user: @user, field: @field, lang: @lang)
    deduped    = deduplicate(candidates)
    RankingService.call(q: @q, lang: @lang, candidates: deduped).first(@limit)
  end

  private

  def deduplicate(candidates)
    best = candidates.each_with_object({}) do |entry, acc|
      key   = entry[:value].downcase
      score = SCORES.fetch(entry[:source], 0)
      if acc[key].nil? || score > SCORES.fetch(acc[key][:source], 0)
        acc[key] = entry
      end
    end
    best.values.map { |e| e[:value] }
  end
end
