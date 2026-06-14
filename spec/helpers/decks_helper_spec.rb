require "rails_helper"

RSpec.describe DecksHelper, type: :helper do
  let(:owner)  { create(:user) }
  let(:viewer) { create(:user) }
  let(:deck)   { create(:deck, user: owner, visibility: "public") }

  describe "#deck_library_state" do
    it "returns :not_logged_in when user is nil" do
      expect(helper.deck_library_state(deck, nil)).to eq(:not_logged_in)
    end

    it "returns :owner when the user owns the deck" do
      expect(helper.deck_library_state(deck, owner)).to eq(:owner)
    end

    it "returns :already_saved when the viewer has a LibraryItem for the deck" do
      create(:library_item, user: viewer, deck: deck)
      expect(helper.deck_library_state(deck, viewer)).to eq(:already_saved)
    end

    it "returns :can_save when user is authenticated, not the owner, and has no LibraryItem" do
      expect(helper.deck_library_state(deck, viewer)).to eq(:can_save)
    end
  end
end
