require "net/http"
require "uri"
require "json"

class DictionaryAdapter
  ENDPOINT = "https://api.datamuse.com/sug"

  def self.fetch(q:, lang:, limit: 8)
    new(q: q, lang: lang, limit: limit).fetch
  end

  def initialize(q:, lang:, limit:)
    @q     = q
    @lang  = lang
    @limit = limit
  end

  def fetch
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(s: @q, max: @limit)
    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).filter_map { |item| item["s"] }.first(@limit)
  rescue StandardError
    []
  end
end
