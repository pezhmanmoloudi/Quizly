class FoldersController < ApplicationController
  before_action :set_folder, only: [:show, :update, :destroy, :rename_modal, :delete_modal, :add_decks_modal, :update_deck_assignments, :tags_modal, :new_tag_modal]

  def index
    @folders = Current.user.folders.includes(:deck_folders).order(created_at: :desc)
  end

  def show
    @folder_tags = @folder.folder_tags.order(:name)
    @active_tag  = @folder_tags.detect { |tag| tag.id == params[:tag_id].to_i } if params[:tag_id].present?
    decks = @folder.decks.includes(:flashcards)
    decks = decks.joins(:deck_folder_tags).where(deck_folder_tags: { folder_tag_id: @active_tag.id }) if @active_tag
    @decks = decks
  end

  def new
    @folder = Current.user.folders.build
    authorize @folder, :create?
  end

  def create
    @folder = Current.user.folders.build(folder_params)
    authorize @folder
    if @folder.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @folder }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def add_decks_modal
    authorize @folder, :add_deck?
    @my_decks      = Current.user.decks.includes(:flashcards).order(updated_at: :desc)
    @explore_decks = Deck.discoverable.where.not(user_id: Current.user.id)
                         .includes(:flashcards, :user).order(updated_at: :desc)
    @folder_deck_ids = DeckFolder.where(folder: @folder).pluck(:deck_id).to_set
  end

  def update_deck_assignments
    authorize @folder, :add_deck?
    requested_ids = Array(params[:deck_ids]).map(&:to_i).to_set
    current_ids   = DeckFolder.where(folder: @folder).pluck(:deck_id).to_set

    valid_ids     = Deck.where(id: requested_ids, user_id: Current.user.id)
                        .or(Deck.discoverable.where(id: requested_ids))
                        .pluck(:id).to_set
    removable_ids = Deck.where(id: current_ids, user_id: Current.user.id)
                        .or(Deck.discoverable.where(id: current_ids))
                        .pluck(:id).to_set

    (valid_ids - current_ids).each do |id|
      Folders::AssignDeckService.call(folder: @folder, deck: Deck.find(id), action: :add)
    end
    (removable_ids - valid_ids).each do |id|
      Folders::AssignDeckService.call(folder: @folder, deck: Deck.find(id), action: :remove)
    end

    redirect_to @folder
  end

  def tags_modal
    authorize @folder, :update?
    load_tags_data
  end

  def new_tag_modal
    authorize @folder, :update?
    load_tags_data
  end

  def rename_modal
    authorize @folder, :update?
  end

  def delete_modal
    authorize @folder, :destroy?
  end

  def update
    authorize @folder
    if @folder.update(folder_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @folder, notice: t("folders.updated") }
      end
    else
      respond_to do |format|
        format.html { render :rename_modal, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @folder
    @folder.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to folders_path, notice: t("folders.deleted") }
    end
  end

  private

  def set_folder
    @folder = Current.user.folders.find(params[:id])
  end

  def load_tags_data
    @folder_tags = @folder.folder_tags.order(:name)
    @deck_counts = DeckFolderTag.where(folder_tag: @folder_tags).group(:folder_tag_id).count
    @recommended = Folders::RecommendedTags.for(@folder)
  end

  def folder_params
    params.require(:folder).permit(:name)
  end
end
