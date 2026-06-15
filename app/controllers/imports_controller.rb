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
      @new_flashcards = @deck.flashcards.order(:position).last(result.imported)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to edit_deck_path(@deck), notice: t("imports.imported", count: result.imported) }
      end
    end
  end

  def csv
    file = params[:file]
    return redirect_to @deck, alert: t("imports.no_file") if file.blank?

    rows = CsvImporter.parse(file: file)
    return redirect_to @deck, alert: t("imports.csv_no_valid_rows") if rows.empty?

    rows.each do |row|
      @deck.flashcards.create(
        front_content: row[:front_content],
        back_content:  row[:back_content]
      )
    end
    redirect_to edit_deck_path(@deck), notice: t("imports.imported", count: rows.size)
  end

  private

  def set_deck
    deck = Deck.find(params[:deck_id])
    deck.unlocked = deck_unlocked?(deck)
    raise ActiveRecord::RecordNotFound unless deck.can_edit?(Current.user)
    @deck = deck
  end
end
