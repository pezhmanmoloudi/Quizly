require "rails_helper"

RSpec.describe TextImporter, type: :service do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user, term_language: "en", definition_language: "fa") }

  describe ".parse" do
    it "parses tab-separated pairs" do
      rows = described_class.parse(text: "hello\tسلام\ncat\tگربه")
      expect(rows).to eq([
        { front_content: "hello", back_content: "سلام" },
        { front_content: "cat",   back_content: "گربه" }
      ])
    end

    it "parses comma-separated pairs when col_sep is comma" do
      rows = described_class.parse(text: "hello,world", col_sep: ",")
      expect(rows).to eq([{ front_content: "hello", back_content: "world" }])
    end

    it "returns [] for blank input" do
      expect(described_class.parse(text: "")).to eq([])
    end

    it "skips lines with only one column" do
      rows = described_class.parse(text: "hello\tworld\njust_one")
      expect(rows).to eq([{ front_content: "hello", back_content: "world" }])
    end
  end

  describe ".call" do
    context "language inheritance from deck" do
      it "assigns front_language from deck.term_language" do
        described_class.call(deck: deck, text: "hello\tسلام")
        card = Flashcard.last
        expect(card.front_language).to eq("en")
      end

      it "assigns back_language from deck.definition_language" do
        described_class.call(deck: deck, text: "hello\tسلام")
        card = Flashcard.last
        expect(card.back_language).to eq("fa")
      end

      it "assigns nil languages when deck has no term_language" do
        null_lang_deck = create(:deck, user: user, term_language: nil, definition_language: nil)
        described_class.call(deck: null_lang_deck, text: "hello\tworld")
        card = Flashcard.last
        expect(card.front_language).to be_nil
        expect(card.back_language).to be_nil
      end
    end

    context "result" do
      it "returns imported count and empty errors on success" do
        result = described_class.call(deck: deck, text: "hello\tworld\ncat\tفیل")
        expect(result.imported).to eq(2)
        expect(result.errors).to be_empty
      end

      it "reports skipped lines" do
        result = described_class.call(deck: deck, text: "hello\tworld\nbadline")
        expect(result.skipped).to eq(1)
      end

      it "returns errors when no valid pairs found" do
        result = described_class.call(deck: deck, text: "badline")
        expect(result.errors).not_to be_empty
      end
    end
  end
end
