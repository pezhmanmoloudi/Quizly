class FolderDecksController < ApplicationController
  before_action :set_folder

  def destroy
    @deck = Deck.find(params[:deck_id])
    authorize @folder, :remove_deck?
    Folders::AssignDeckService.call(folder: @folder, deck: @deck, action: :remove)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @folder, notice: t("folders.deck_removed") }
    end
  end

  private

  def set_folder
    @folder = Current.user.folders.find(params[:folder_id])
  end
end
