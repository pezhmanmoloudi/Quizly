class StarredCardsController < ApplicationController
  before_action :set_card_progress

  def create
    @card_progress.update!(starred: true)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def destroy
    @card_progress.update!(starred: false)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end

  private

  def set_card_progress
    @card_progress = Current.user.card_progresses.find(params[:card_progress_id])
  end
end
