class ImportsController < ApplicationController
  before_action :set_deck

  def new
    @tab = params[:tab].in?(%w[text csv]) ? params[:tab] : "text"
  end

  def text
    text = params[:text].to_s.strip
    if text.blank?
      flash.now[:alert] = "Please paste some text to import."
      @tab = "text"
      return render :new, status: :unprocessable_entity
    end

    result = TextImporter.call(
      deck: @deck,
      text: text,
      col_sep: params[:col_sep].presence || "\t"
    )

    if result.errors.empty?
      msg = "Imported #{result.imported} card#{"s" unless result.imported == 1}."
      msg += " #{result.skipped} line#{"s" unless result.skipped == 1} skipped." if result.skipped > 0
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
      flash.now[:alert] = "Please select a CSV file."
      @tab = "csv"
      return render :new, status: :unprocessable_entity
    end

    result = CsvImporter.call(deck: @deck, file: file)

    if result.errors.empty?
      msg = "Imported #{result.imported} card#{"s" unless result.imported == 1}."
      msg += " #{result.skipped} row#{"s" unless result.skipped == 1} skipped." if result.skipped > 0
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
