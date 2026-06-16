class DeckCopyController < ApplicationController
  include DeckScoped

  before_action :set_deck
  before_action :resolve_access

  def create
    authorize @deck, :copy?
    copied = Decks::CopyService.call(
      source_deck: @deck,
      user:        Current.user,
      name:        t("decks.action.copy_name", name: @deck.name)
    )
    redirect_to deck_path(copied), notice: t("decks.action.copied")
  rescue Pundit::NotAuthorizedError
    redirect_to fallback_destination, alert: t("decks.not_available")
  end
end
