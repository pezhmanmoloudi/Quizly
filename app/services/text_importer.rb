class TextImporter
  Result = Data.define(:imported, :skipped, :errors)

  def self.call(deck:, text:, col_sep: "\t")
    new(deck: deck, text: text, col_sep: col_sep).call
  end

  def initialize(deck:, text:, col_sep: "\t")
    @deck    = deck
    @text    = text
    @col_sep = col_sep
  end

  def call
    lines = @text.split("\n").map(&:strip).reject(&:blank?)
    pairs = lines.map { |l| l.split(@col_sep, 2) }.select { |p| p.size == 2 && p.all?(&:present?) }
    skipped = lines.size - pairs.size

    return Result.new(imported: 0, skipped: lines.size, errors: [I18n.t("imports.text_no_valid_pairs")]) if pairs.empty?

    next_pos = (@deck.flashcards.maximum(:position) || -1) + 1
    now = Time.current

    records = pairs.each_with_index.map do |(front, back), i|
      { deck_id: @deck.id, front_content: front.strip, back_content: back.strip,
        position: next_pos + i, created_at: now, updated_at: now }
    end

    Flashcard.insert_all(records)
    Result.new(imported: records.size, skipped: skipped, errors: [])
  rescue => e
    Result.new(imported: 0, skipped: 0, errors: [e.message])
  end
end
