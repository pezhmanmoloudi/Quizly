class ImportsController < ApplicationController
  before_action :set_deck

  def new
    redirect_to @deck
  end

  def text
    text = params[:text].to_s.strip
    return redirect_to @deck, alert: t("imports.no_text") if text.blank?

    col_sep = params[:col_sep].presence || "\t"
    row_sep = params[:row_sep].presence || "\n"
    result  = TextImporter.call(deck: @deck, text: text, col_sep: col_sep, row_sep: row_sep)

    if result.errors.any?
      redirect_to @deck, alert: result.errors.first
    else
      redirect_to @deck, notice: t("imports.imported", count: result.imported)
    end
  end

  def csv
    file = params[:file]
    if file.blank?
      return redirect_to @deck, alert: t("imports.no_file")
    end

    rows = CsvImporter.parse(file: file)

    if rows.empty?
      return redirect_to @deck, alert: t("imports.csv_no_valid_rows")
    end

    @draft_rows = rows
    @imported   = true
    @existing   = @deck.flashcards.to_a
    render "decks/cards"
  end

  private

  def set_deck
    deck = Deck.find(params[:deck_id])
    raise ActiveRecord::RecordNotFound unless deck.can_edit?(Current.user, session_auth: deck_session_auth(deck))
    @deck = deck
  end
end
