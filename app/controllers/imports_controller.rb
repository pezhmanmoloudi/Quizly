class ImportsController < ApplicationController
  before_action :set_deck

  def new
    @tab = params[:tab].in?(%w[text csv]) ? params[:tab] : "text"
  end

  def text
    text = params[:text].to_s.strip
    if text.blank?
      flash.now[:alert] = t("imports.no_text")
      @tab = "text"
      return render :new, status: :unprocessable_entity
    end

    rows = TextImporter.parse(text: text, col_sep: params[:col_sep].presence || "\t")

    if rows.empty?
      flash.now[:alert] = t("imports.text_no_valid_pairs")
      @tab = "text"
      return render :new, status: :unprocessable_entity
    end

    @draft_rows = rows
    @imported   = true
    @existing   = @deck.flashcards.to_a
    render "decks/cards"
  end

  def csv
    file = params[:file]
    if file.blank?
      flash.now[:alert] = t("imports.no_file")
      @tab = "csv"
      return render :new, status: :unprocessable_entity
    end

    rows = CsvImporter.parse(file: file)

    if rows.empty?
      flash.now[:alert] = t("imports.csv_no_valid_rows")
      @tab = "csv"
      return render :new, status: :unprocessable_entity
    end

    @draft_rows = rows
    @imported   = true
    @existing   = @deck.flashcards.to_a
    render "decks/cards"
  end

  private

  def set_deck
    @deck = Current.user.decks.find(params[:deck_id])
  end
end
