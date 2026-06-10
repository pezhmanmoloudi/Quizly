class SuggestionQuery
  KNOWN_LANGS  = Language::ALL_LANGUAGES.keys.to_set.freeze
  DEFAULT_LANG = "en"
  CACHE_TTL    = 24.hours

  def self.call(q:, lang:, limit: 8)
    new(
      q:     q.to_s.strip.downcase,
      lang:  lang.to_s.strip,
      limit: limit
    ).call
  end

  def initialize(q:, lang:, limit:)
    @q     = q
    @lang  = KNOWN_LANGS.include?(lang) ? lang : DEFAULT_LANG
    @limit = limit
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      DictionaryAdapter.fetch(q: @q, lang: @lang, limit: @limit)
    end
  end

  private

  def cache_key
    "sug:#{@lang}:#{@q[0, 3]}"
  end
end
