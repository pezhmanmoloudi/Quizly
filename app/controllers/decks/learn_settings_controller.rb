module Decks
  class LearnSettingsController < ApplicationController
    def update
      deck = Current.user.decks.find(params[:id])
      if deck.update(learn_settings_params)
        redirect_to learn_deck_path(deck), notice: t("learn.settings.saved")
      else
        redirect_to learn_deck_path(deck), alert: t("learn.settings.invalid")
      end
    end

    private

    def learn_settings_params
      params.require(:deck).permit(
        :learn_new_cards_limit,
        :learn_mastery_threshold,
        :learn_hints_enabled,
        :learn_weak_cards_priority
      )
    end
  end
end
