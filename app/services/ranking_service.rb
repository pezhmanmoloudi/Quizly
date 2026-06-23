class RankingService
  EXACT_MATCH_BONUS  = 100
  PREFIX_MATCH_BONUS =  50
  SCRIPT_MATCH_BONUS =  30

  def self.call(q:, lang:, candidates:)
    new(q:, lang:, candidates:).call
  end

  def initialize(q:, lang:, candidates:)
    @q               = q.to_s.strip
    @lang            = lang.to_s.strip
    @candidates      = candidates
    @expected_script = ScriptDetector.for_lang(@lang)
  end

  def call
    @candidates
      .map    { |value| { value: value, score: score(value) } }
      .sort_by { |e| [-e[:score], e[:value].length, e[:value]] }
      .map    { |e| e[:value] }
  end

  private

  def score(value)
    pts  = 0
    pts += EXACT_MATCH_BONUS  if exact_match?(value)
    pts += PREFIX_MATCH_BONUS if prefix_match?(value)
    pts += SCRIPT_MATCH_BONUS if script_matches?(value)
    pts
  end

  def exact_match?(value)
    value.downcase == @q.downcase
  end

  def prefix_match?(value)
    value.downcase.start_with?(@q.downcase)
  end

  def script_matches?(value)
    return true if @lang.blank?
    ScriptDetector.call(value) == @expected_script
  end
end
