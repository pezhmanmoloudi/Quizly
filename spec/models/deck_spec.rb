require "rails_helper"

RSpec.describe Deck, type: :model do
  describe "associations" do
    it "belongs to a user" do
      deck = build(:deck)
      expect(deck.user).to be_present
    end

    it "has many flashcards" do
      assoc = described_class.reflect_on_association(:flashcards)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "is valid with a name, optional description, and optional language_code" do
      deck = build(:deck, name: "Spanish Vocab", description: "Common words", language_code: "es")
      expect(deck).to be_valid
    end

    it "is valid without a description" do
      deck = build(:deck, description: nil)
      expect(deck).to be_valid
    end

    it "is valid without a language_code" do
      deck = build(:deck, language_code: nil)
      expect(deck).to be_valid
    end

    it "is invalid without a name" do
      deck = build(:deck, name: "")
      expect(deck).not_to be_valid
      expect(deck.errors[:name]).to include("can't be blank")
    end

    it "is invalid with a name longer than 100 characters" do
      deck = build(:deck, name: "A" * 101)
      expect(deck).not_to be_valid
      expect(deck.errors[:name]).to include("is too long (maximum is 100 characters)")
    end

    it "is valid with a name of exactly 100 characters" do
      deck = build(:deck, name: "A" * 100)
      expect(deck).to be_valid
    end
  end

  describe "dependent destruction" do
    it "destroys associated flashcards when the deck is deleted" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      expect { deck.destroy }.to change(Flashcard, :count).by(-1)
    end
  end
end
