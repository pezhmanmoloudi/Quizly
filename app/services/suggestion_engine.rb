class SuggestionEngine
  FETCH_LIMIT = 10
  ALLOWED_COLUMNS = %w[front_content back_content].freeze

  def self.call(q:, scope:, col:, limit: FETCH_LIMIT)
    new(q:, scope:, col:, limit:).call
  end

  def initialize(q:, scope:, col:, limit:)
    @q     = q.to_s.strip
    @scope = scope
    @col   = col.to_s
    @limit = limit
  end

  def call
    return [] if @q.blank?
    raise ArgumentError, "Invalid column: #{@col.inspect}" unless ALLOWED_COLUMNS.include?(@col)

    @scope
      .where("LOWER(#{@col}) LIKE LOWER(?) ESCAPE '\\'", like_pattern)
      .limit(@limit)
      .pluck(@col)
  end

  private

  def like_pattern
    "#{Flashcard.sanitize_sql_like(@q)}%"
  end
end
