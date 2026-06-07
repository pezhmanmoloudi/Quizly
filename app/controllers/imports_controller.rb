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

    result = TextImporter.call(
      deck: @deck,
      text: text,
      col_sep: params[:col_sep].presence || "\t"
    )

    if result.errors.empty?
      msg = t("imports.imported", count: result.imported)
      msg += " #{t("imports.skipped", count: result.skipped)}" if result.skipped > 0
      redirect_to @deck, notice: msg
    else
      flash.now[:alert] = result.errors.first
      @tab = "text"
      render :new, status: :unprocessable_entity
    end
  end

  def csv
    file = params[:file]
    if file.blank?
      flash.now[:alert] = t("imports.no_file")
      @tab = "csv"
      return render :new, status: :unprocessable_entity
    end

    result = CsvImporter.call(deck: @deck, file: file)

    if result.errors.empty?
      msg = t("imports.imported", count: result.imported)
      msg += " #{t("imports.skipped", count: result.skipped)}" if result.skipped > 0
      redirect_to @deck, notice: msg
    else
      flash.now[:alert] = result.errors.first
      @tab = "csv"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_deck
    @deck = Current.user.decks.find(params[:deck_id])
  end
end
