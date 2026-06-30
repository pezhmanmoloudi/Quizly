class FolderDeckTagsController < ApplicationController
  before_action :set_folder

  def edit
    authorize @folder, :update?
    @deck       = @folder.decks.find(params[:id])
    @folder_tags = @folder.folder_tags.order(:name)
    @tagged_ids  = DeckFolderTag.where(deck: @deck, folder_tag: @folder_tags)
                                .pluck(:folder_tag_id).to_set
  end

  def update
    authorize @folder, :update?
    @deck = @folder.decks.find(params[:id])
    sync_tags
    @decks = @folder.decks.includes(:flashcards)
    @folder_tags = @folder.folder_tags.order(:name)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @folder, notice: t("folders.tags.deck_updated") }
    end
  end

  private

  def set_folder
    @folder = Current.user.folders.find(params[:folder_id])
  end

  # Apply only this folder's own tags to the deck — never create decks or tags.
  def sync_tags
    folder_tag_ids = @folder.folder_tags.ids.to_set
    requested_ids  = Array(params[:tag_ids]).map(&:to_i).to_set & folder_tag_ids
    current_ids    = DeckFolderTag.where(deck: @deck, folder_tag_id: folder_tag_ids)
                                  .pluck(:folder_tag_id).to_set

    (requested_ids - current_ids).each do |id|
      FolderTags::AssignDeckService.call(folder_tag: @folder.folder_tags.find(id), deck: @deck, action: :add)
    end
    (current_ids - requested_ids).each do |id|
      FolderTags::AssignDeckService.call(folder_tag: @folder.folder_tags.find(id), deck: @deck, action: :remove)
    end
  end
end
