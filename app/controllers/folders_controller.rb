class FoldersController < ApplicationController
  before_action :set_folder, only: [:show, :update, :destroy, :rename_modal, :delete_modal]

  def index
    @folders = Current.user.folders.includes(:deck_folders).order(created_at: :desc)
  end

  def show
    @decks = @folder.decks.includes(:flashcards)
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

  def folder_params
    params.require(:folder).permit(:name)
  end
end
