class FolderDeckAssignmentsController < ApplicationController
  def new
    @deck = Deck.find(params[:deck_id])
    @user_folders = Current.user.folders.order(name: :asc)
    @deck_folder_ids = DeckFolder.where(folder_id: @user_folders, deck_id: @deck.id).pluck(:folder_id)
  end

  def create
    @deck = Deck.find(params[:deck_id])
    folder_ids = Array(params[:folder_ids]).map(&:to_i).uniq

    user_folder_ids = Current.user.folders.pluck(:id)
    current_ids     = DeckFolder.where(folder_id: user_folder_ids, deck_id: @deck.id).pluck(:folder_id)

    (folder_ids - current_ids).each do |id|
      folder = Current.user.folders.find_by(id:)
      Folders::AssignDeckService.call(folder:, deck: @deck, action: :add) if folder
    end

    (current_ids - folder_ids).each do |id|
      folder = Current.user.folders.find_by(id:)
      Folders::AssignDeckService.call(folder:, deck: @deck, action: :remove) if folder
    end

    @is_saved = folder_ids.any?

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: explore_path }
    end
  end
end
