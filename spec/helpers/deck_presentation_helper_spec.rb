require "rails_helper"

RSpec.describe DeckPresentationHelper, type: :helper do
  describe "#deck_cover_class" do
    it "is deterministic per deck id" do
      deck = build_stubbed(:deck, id: 7)
      expect(helper.deck_cover_class(deck)).to eq("deck-cover--c1")
    end
  end

  describe "#deck_cover_text" do
    it "uses the first flashcard's term when present" do
      deck = create(:deck)
      create(:flashcard, deck: deck, front_content: "Hallo!")

      expect(helper.deck_cover_text(deck)).to eq("Hallo!")
    end

    it "falls back to the deck name when there are no cards" do
      deck = create(:deck, name: "Spanish")
      expect(helper.deck_cover_text(deck)).to eq("Spanis")
    end
  end

  describe "#deck_flag" do
    it "returns a flag for a mapped term language" do
      deck = build_stubbed(:deck, term_language: "de")
      expect(helper.deck_flag(deck)).to eq("🇩🇪")
    end

    it "returns nil for an unmapped term language" do
      deck = build_stubbed(:deck, term_language: "en")
      expect(helper.deck_flag(deck)).to be_nil
    end
  end
end
