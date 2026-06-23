require "csv"

class CsvImporter
  Result = Data.define(:imported, :skipped, :errors)

  FRONT_HEADERS = %w[front term question].freeze
  BACK_HEADERS  = %w[back definition answer].freeze

  class << self
    def call(deck:, file:)
      new(deck: deck, file: file).call
    end

    def parse(file:)
      return [] if file.blank?

      table = CSV.read(file.path, headers: true, encoding: "bom|utf-8", liberal_parsing: true)
      return [] if table.headers.size < 2

      front_col, back_col = detect_columns(table.headers)

      table.filter_map do |row|
        front = row[front_col]&.strip
        back  = row[back_col]&.strip
        { front_content: front, back_content: back } if front.present? && back.present?
      end
    rescue
      []
    end

    private

    def detect_columns(headers)
      normalised = headers.map { |h| h.to_s.strip.downcase }
      front = normalised.find { |h| FRONT_HEADERS.include?(h) } || headers[0]
      back  = normalised.find { |h| BACK_HEADERS.include?(h) }  || headers[1]

      front = headers[normalised.index(front)] if normalised.include?(front)
      back  = headers[normalised.index(back)]  if normalised.include?(back)

      [front, back]
    end
  end

  def initialize(deck:, file:)
    @deck = deck
    @file = file
  end

  def call
    rows    = self.class.parse(file: @file)
    skipped = begin
      table = CSV.read(@file.path, headers: true, encoding: "bom|utf-8", liberal_parsing: true)
      table.size - rows.size
    rescue
      0
    end

    if rows.empty?
      return Result.new(imported: 0, skipped: skipped,
                        errors: [skipped > 0 ? I18n.t("imports.csv_no_valid_rows") : I18n.t("imports.csv_too_few_columns")])
    end

    next_pos = (@deck.flashcards.maximum(:position) || -1) + 1
    now = Time.current

    records = rows.each_with_index.map do |row, i|
      { deck_id: @deck.id, front_content: row[:front_content], back_content: row[:back_content],
        front_language: @deck.term_language, back_language: @deck.definition_language,
        position: next_pos + i, created_at: now, updated_at: now }
    end

    Flashcard.insert_all(records)
    Result.new(imported: records.size, skipped: skipped, errors: [])
  rescue CSV::MalformedCSVError => e
    Result.new(imported: 0, skipped: 0, errors: [I18n.t("imports.csv_invalid_format", message: e.message)])
  rescue => e
    Result.new(imported: 0, skipped: 0, errors: [e.message])
  end
end
