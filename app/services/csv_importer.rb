require "csv"

class CsvImporter
  Result = Data.define(:imported, :skipped, :errors)

  FRONT_HEADERS = %w[front term question].freeze
  BACK_HEADERS  = %w[back definition answer].freeze

  def self.call(deck:, file:)
    new(deck: deck, file: file).call
  end

  def initialize(deck:, file:)
    @deck = deck
    @file = file
  end

  def call
    table = CSV.read(@file.path, headers: true, encoding: "bom|utf-8", liberal_parsing: true)

    raise I18n.t("imports.csv_too_few_columns") if table.headers.size < 2

    front_col, back_col = detect_columns(table.headers)
    next_pos = (@deck.flashcards.maximum(:position) || -1) + 1
    now = Time.current

    records = []
    skipped = 0

    table.each do |row|
      front = row[front_col]&.strip
      back  = row[back_col]&.strip
      if front.present? && back.present?
        records << { deck_id: @deck.id, front_content: front, back_content: back,
                     position: next_pos + records.size, created_at: now, updated_at: now }
      else
        skipped += 1
      end
    end

    return Result.new(imported: 0, skipped: skipped, errors: [I18n.t("imports.csv_no_valid_rows")]) if records.empty?

    Flashcard.insert_all(records)
    Result.new(imported: records.size, skipped: skipped, errors: [])
  rescue CSV::MalformedCSVError => e
    Result.new(imported: 0, skipped: 0, errors: [I18n.t("imports.csv_invalid_format", message: e.message)])
  rescue => e
    Result.new(imported: 0, skipped: 0, errors: [e.message])
  end

  private

  def detect_columns(headers)
    normalised = headers.map { |h| h.to_s.strip.downcase }
    front = normalised.find { |h| FRONT_HEADERS.include?(h) } || headers[0]
    back  = normalised.find { |h| BACK_HEADERS.include?(h) }  || headers[1]

    # map back to original header value
    front = headers[normalised.index(front)] if normalised.include?(front)
    back  = headers[normalised.index(back)]  if normalised.include?(back)

    [front, back]
  end
end
