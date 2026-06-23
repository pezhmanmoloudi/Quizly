require "rails_helper"

RSpec.describe Flashcard, type: :model do
  describe "associations" do
    it "belongs to a deck" do
      assoc = described_class.reflect_on_association(:deck)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "has many card_progresses with dependent destroy" do
      assoc = described_class.reflect_on_association(:card_progresses)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has one attached image" do
      expect(described_class.reflect_on_all_attachments.map(&:name)).to include(:image)
    end
  end

  describe "validations" do
    it "is valid with front_content and back_content" do
      flashcard = build(:flashcard)
      expect(flashcard).to be_valid
    end

    it "is invalid without front_content" do
      flashcard = build(:flashcard, front_content: "")
      expect(flashcard).not_to be_valid
      expect(flashcard.errors[:front_content]).to include("can't be blank")
    end

    it "is invalid without back_content" do
      flashcard = build(:flashcard, back_content: "")
      expect(flashcard).not_to be_valid
      expect(flashcard.errors[:back_content]).to include("can't be blank")
    end
  end

  describe "default scope" do
    it "orders by position then id by default" do
      deck = create(:deck)
      third  = create(:flashcard, deck: deck, position: 2)
      first  = create(:flashcard, deck: deck, position: 0)
      second = create(:flashcard, deck: deck, position: 1)
      expect(deck.flashcards.to_a).to eq([first, second, third])
    end
  end

  describe "#inherit_language_from_deck" do
    it "sets front_language from deck.term_language on create" do
      deck = create(:deck, term_language: "en", definition_language: "fa")
      card = create(:flashcard, deck: deck)
      expect(card.front_language).to eq("en")
    end

    it "sets back_language from deck.definition_language on create" do
      deck = create(:deck, term_language: "en", definition_language: "fa")
      card = create(:flashcard, deck: deck)
      expect(card.back_language).to eq("fa")
    end

    it "leaves front_language nil when deck.term_language is nil" do
      deck = create(:deck, term_language: nil, definition_language: nil)
      card = create(:flashcard, deck: deck)
      expect(card.front_language).to be_nil
    end

    it "does not override an explicitly set front_language" do
      deck = create(:deck, term_language: "en", definition_language: "fa")
      card = create(:flashcard, deck: deck, front_language: "de")
      expect(card.front_language).to eq("de")
    end

    it "does not override an explicitly set back_language" do
      deck = create(:deck, term_language: "en", definition_language: "fa")
      card = create(:flashcard, deck: deck, back_language: "ar")
      expect(card.back_language).to eq("ar")
    end
  end

  describe "dependent destruction" do
    it "destroys associated card_progresses when deleted" do
      user      = create(:user)
      flashcard = create(:flashcard)
      create(:card_progress, user: user, flashcard: flashcard)
      expect { flashcard.destroy }.to change(CardProgress, :count).by(-1)
    end
  end
end
