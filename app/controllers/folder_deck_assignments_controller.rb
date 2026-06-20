class FolderDeckAssignmentsController < ApplicationController
  def new
    @deck = Deck.find(params[:deck_id])
    @user_folders = Current.user.folders.order(name: :asc)
    @deck_folder_ids = DeckFolder.where(folder_id: @user_folders, deck_id: @deck.id).pluck(:folder_id)
  end

  def create
    @deck = Deck.find(params[:deck_id])
    folder_ids = Array(params[:folder_ids]).map(&:to_i).uniq

    Current.user.folders.where(id: folder_ids).each do |folder|
      Folders::AssignDeckService.call(folder: folder, deck: @deck, action: :add)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: explore_path }
    end
  end
end
