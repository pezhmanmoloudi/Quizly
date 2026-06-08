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

  describe "#tag_list" do
    it "returns an empty array when subject_tags is nil" do
      deck = build(:deck, subject_tags: nil)
      expect(deck.tag_list).to eq([])
    end

    it "parses comma-separated tags into an array" do
      deck = build(:deck, subject_tags: "biology, anatomy, exam2025")
      expect(deck.tag_list).to eq(%w[biology anatomy exam2025])
    end

    it "ignores blank entries" do
      deck = build(:deck, subject_tags: "biology,,  ")
      expect(deck.tag_list).to eq(["biology"])
    end
  end

  describe "#tag_list=" do
    it "normalises and stores tags as a comma-separated string" do
      deck = build(:deck)
      deck.tag_list = "Biology,  anatomy , EXAM2025"
      expect(deck.subject_tags).to eq("Biology, anatomy, EXAM2025")
    end
  end

  describe "visibility" do
    it "defaults to public" do
      deck = Deck.new(name: "Test", user: build(:user))
      expect(deck.visibility).to eq("public")
    end

    it "is invalid with an unsupported visibility value" do
      deck = build(:deck, visibility: "secret")
      expect(deck).not_to be_valid
    end

    it "recognises public? and private? helpers" do
      expect(build(:deck, visibility: "public").public?).to be true
      expect(build(:deck, visibility: "private").private?).to be true
    end
  end

  describe "minimum card validation" do
    it "skips validation when validate_card_count is not set" do
      deck = build(:deck)
      expect(deck).to be_valid
    end

    it "is invalid when validate_card_count is set and fewer than 2 cards" do
      deck = build(:deck)
      deck.validate_card_count = true
      deck.flashcards.build(front_content: "Q", back_content: "A", position: 1)
      expect(deck).not_to be_valid
      expect(deck.errors[:base]).to include("You need at least 2 cards to save a deck.")
    end

    it "is valid when validate_card_count is set and 2+ cards provided" do
      deck = build(:deck, :with_cards)
      deck.validate_card_count = true
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
