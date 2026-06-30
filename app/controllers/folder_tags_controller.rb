class FolderTagsController < ApplicationController
  before_action :set_folder

  def create
    authorize @folder, :update?
    @folder_tag = @folder.folder_tags.build(folder_tag_params)
    if @folder_tag.save
      load_tags_data
      @decks = @folder.decks.includes(:flashcards)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @folder, notice: t("folders.tags.created") }
      end
    else
      respond_with_error
    end
  end

  def edit
    authorize @folder, :update?
    @folder_tag = @folder.folder_tags.find(params[:id])
  end

  def update
    authorize @folder, :update?
    @folder_tag = @folder.folder_tags.find(params[:id])
    if @folder_tag.update(folder_tag_params)
      @decks = @folder.decks.includes(:flashcards)
      respond_to do |format|
        format.turbo_stream { render :reopen_manage }
        format.html { redirect_to @folder, notice: t("folders.tags.renamed") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def delete_modal
    authorize @folder, :update?
    @folder_tag = @folder.folder_tags.find(params[:id])
  end

  def destroy
    authorize @folder, :update?
    @folder_tag = @folder.folder_tags.find(params[:id])
    @folder_tag.destroy
    @decks = @folder.decks.includes(:flashcards)
    respond_to do |format|
      format.turbo_stream { render :reopen_manage }
      format.html { redirect_to @folder, notice: t("folders.tags.deleted") }
    end
  end

  private

  def set_folder
    @folder = Current.user.folders.find(params[:folder_id])
  end

  def folder_tag_params
    params.require(:folder_tag).permit(:name)
  end

  def load_tags_data
    @folder_tags = @folder.folder_tags.order(:name)
    @deck_counts = DeckFolderTag.where(folder_tag: @folder_tags).group(:folder_tag_id).count
    @recommended = Folders::RecommendedTags.for(@folder)
  end

  def respond_with_error
    load_tags_data
    @tag_error = @folder_tag.errors.full_messages.first
    template   = params[:tag_form_context] == "new" ? "folders/new_tag_modal" : "folders/tags_modal"
    render template: template, status: :unprocessable_entity
  end
end
