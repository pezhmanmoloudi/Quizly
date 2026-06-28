class DeckExportsController < ApplicationController
  before_action :set_deck

  def show
    authorize @deck, :export?
    send_data tsv_content,
              filename: "#{@deck.name.parameterize}.txt",
              type: "text/plain",
              disposition: "attachment"
  end

  private

  def set_deck
    @deck = Deck.find(params[:id])
  end

  def tsv_content
    @deck.flashcards.where(deleted_at: nil).order(:position).map do |card|
      "#{card.front_content}\t#{card.back_content}"
    end.join("\n")
  end
end
