require "rails_helper"

RSpec.describe "Decks::LearnSettings#update", type: :request do
  let(:owner)      { create(:user) }
  let(:other_user) { create(:user) }
  let(:deck)       { create(:deck, user: owner) }

  context "when authenticated as owner" do
    before { sign_in(owner) }

    it "updates learn_mastery_threshold and redirects to learn path" do
      patch learn_settings_deck_path(deck), params: { deck: { learn_mastery_threshold: 90 } }
      expect(deck.reload.learn_mastery_threshold).to eq 90
      expect(response).to redirect_to(learn_deck_path(deck))
    end

    it "updates learn_new_cards_limit" do
      patch learn_settings_deck_path(deck), params: { deck: { learn_new_cards_limit: 5 } }
      expect(deck.reload.learn_new_cards_limit).to eq 5
    end

    it "updates learn_hints_enabled to false" do
      patch learn_settings_deck_path(deck), params: { deck: { learn_hints_enabled: "false" } }
      expect(deck.reload.learn_hints_enabled).to eq false
    end

    it "updates learn_weak_cards_priority" do
      patch learn_settings_deck_path(deck), params: { deck: { learn_weak_cards_priority: "high" } }
      expect(deck.reload.learn_weak_cards_priority).to eq "high"
    end

    it "redirects with alert on invalid threshold value" do
      patch learn_settings_deck_path(deck), params: { deck: { learn_mastery_threshold: 99 } }
      expect(deck.reload.learn_mastery_threshold).to eq 80
      expect(response).to redirect_to(learn_deck_path(deck))
      expect(flash[:alert]).to be_present
    end
  end

  context "when authenticated as non-owner" do
    before { sign_in(other_user) }

    it "does not update and redirects via RecordNotFound handler" do
      patch learn_settings_deck_path(deck), params: { deck: { learn_mastery_threshold: 90 } }
      expect(deck.reload.learn_mastery_threshold).to eq 80
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      patch learn_settings_deck_path(deck), params: { deck: { learn_mastery_threshold: 90 } }
      expect(response).to redirect_to(login_path)
    end
  end
end
