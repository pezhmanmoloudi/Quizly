class TextImporter
  Result = Data.define(:imported, :skipped, :errors)

  def self.call(deck:, text:, col_sep: "\t")
    new(deck: deck, text: text, col_sep: col_sep).call
  end

  def self.parse(text:, col_sep: "\t")
    return [] if text.blank?

    lines = text.split("\n").map(&:strip).reject(&:blank?)
    lines.map { |l| l.split(col_sep, 2) }
         .select { |p| p.size == 2 && p.all?(&:present?) }
         .map { |front, back| { front_content: front.strip, back_content: back.strip } }
  rescue
    []
  end

  def initialize(deck:, text:, col_sep: "\t")
    @deck    = deck
    @text    = text
    @col_sep = col_sep
  end

  def call
    rows = self.class.parse(text: @text, col_sep: @col_sep)
    skipped = @text.split("\n").map(&:strip).reject(&:blank?).size - rows.size

    return Result.new(imported: 0, skipped: skipped, errors: [I18n.t("imports.text_no_valid_pairs")]) if rows.empty?

    next_pos = (@deck.flashcards.maximum(:position) || -1) + 1
    now = Time.current

    records = rows.each_with_index.map do |row, i|
      { deck_id: @deck.id, front_content: row[:front_content], back_content: row[:back_content],
        position: next_pos + i, created_at: now, updated_at: now }
    end

    Flashcard.insert_all(records)
    Result.new(imported: records.size, skipped: skipped, errors: [])
  rescue => e
    Result.new(imported: 0, skipped: 0, errors: [e.message])
  end
end
