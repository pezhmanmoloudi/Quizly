require "rails_helper"

RSpec.describe FlashcardSuggestionQuery, type: :service do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }
  let(:other) { create(:user) }

  def call(q:, field: "front", lang: "", limit: 3)
    described_class.call(q:, field:, lang:, user:, limit:)
  end

  describe ".call" do
    context "when q is blank" do
      it "returns [] for empty string" do
        expect(call(q: "")).to eq([])
      end

      it "returns [] for whitespace" do
        expect(call(q: "   ")).to eq([])
      end
    end

    context "own primary field (score 100)" do
      before do
        create(:flashcard, deck: deck, front_content: "elephant", public: false)
      end

      it "includes own private cards" do
        expect(call(q: "ele", lang: "en")).to include("elephant")
      end

      it "does not require own cards to be public" do
        expect(call(q: "ele")).to include("elephant")
      end
    end

    context "public primary field (score 80)" do
      before do
        create(:flashcard, deck: create(:deck, user: other, term_language: "en"),
               front_content: "elephant", public: true)
      end

      it "includes public cards from other users" do
        expect(call(q: "ele", lang: "en")).to include("elephant")
      end

      it "excludes private cards from other users" do
        create(:flashcard, deck: create(:deck, user: other),
               front_content: "elaborate", public: false)

        expect(call(q: "ela")).not_to include("elaborate")
      end
    end

    context "own opposite field (score 60)" do
      before do
        create(:flashcard, deck: deck,
               front_content: "xyz_no_match", back_content: "elephant", public: false)
      end

      it "includes own cards matched on the opposite field" do
        expect(call(q: "ele", field: "front", lang: "en")).to include("elephant")
      end

      it "does not apply the language filter to the opposite-field bucket" do
        create(:flashcard, deck: deck,
               front_content: "abc_no_match", back_content: "elaborate", public: false)

        expect(call(q: "ela", field: "front", lang: "en")).to include("elaborate")
      end
    end

    context "public opposite field (score 40)" do
      before do
        create(:flashcard, deck: create(:deck, user: other),
               front_content: "xyz_no_match", back_content: "elephant", public: true)
      end

      it "includes public cross-field suggestions" do
        expect(call(q: "ele", field: "front")).to include("elephant")
      end
    end

    context "source deduplication" do
      it "keeps both when own-primary and public-primary have different words" do
        create(:flashcard, deck: deck, front_content: "apple", public: false)
        create(:flashcard, deck: create(:deck, user: other),
               front_content: "apricot", public: true)

        results = call(q: "ap")
        expect(results).to include("apple", "apricot")
      end

      it "includes words matched on both primary and opposite fields" do
        create(:flashcard, deck: deck, front_content: "elephant",
               back_content: "xyz", public: false)
        create(:flashcard, deck: deck, front_content: "xyz_front",
               back_content: "element", public: false)

        results = call(q: "ele")
        expect(results).to include("elephant", "element")
      end
    end

    context "deduplication" do
      it "returns only one entry when the same word appears in multiple buckets" do
        create(:flashcard, deck: deck, front_content: "elephant", public: false)
        create(:flashcard, deck: create(:deck, user: other),
               front_content: "elephant", public: true)

        results = call(q: "ele")
        expect(results.count { |w| w.downcase == "elephant" }).to eq(1)
      end

      it "normalises case variants to a single result, preserving highest-scored casing" do
        create(:flashcard, deck: deck, front_content: "Elephant", public: false)
        create(:flashcard, deck: create(:deck, user: other),
               front_content: "elephant", public: true)

        results = call(q: "ele")
        elephant_results = results.select { |w| w.downcase == "elephant" }
        expect(elephant_results.size).to eq(1)
        expect(elephant_results.first).to eq("Elephant")
      end
    end

    context "language filtering" do
      it "includes cards matching the given language on the primary field" do
        create(:flashcard, deck: create(:deck, user: other, term_language: "en"),
               front_content: "elephant", public: true)
        create(:flashcard, deck: create(:deck, user: other, term_language: "de"),
               front_content: "elefant", public: true)

        results = call(q: "ele", lang: "en")
        expect(results).to include("elephant")
        expect(results).not_to include("elefant")
      end

      it "returns all languages when lang is blank" do
        create(:flashcard, deck: create(:deck, user: other, term_language: "en"),
               front_content: "elephant", public: true)
        create(:flashcard, deck: create(:deck, user: other, term_language: "de"),
               front_content: "elefant", public: true)

        results = call(q: "ele", lang: "")
        expect(results).to include("elephant")
        expect(results).to include("elefant")
      end
    end

    context "result limit" do
      it "returns at most the default limit of 3" do
        5.times do |i|
          create(:flashcard, deck: create(:deck, user: other),
                 front_content: "item#{i}", public: true)
        end
        expect(call(q: "item").size).to be <= 3
      end

      it "honours a custom limit" do
        4.times do |i|
          create(:flashcard, deck: deck, front_content: "word#{i}", public: false)
        end
        expect(call(q: "word", limit: 2).size).to be <= 2
      end
    end

    context "soft-deleted cards" do
      it "never returns a deleted card" do
        card = create(:flashcard, deck: deck, front_content: "elephant", public: false)
        card.soft_delete!

        expect(call(q: "ele")).not_to include("elephant")
      end
    end

    context "field: back" do
      it "uses back_content as primary and front_content as opposite" do
        create(:flashcard, deck: deck, back_content: "elephant", public: false)
        create(:flashcard, deck: deck, front_content: "elbow", back_content: "xyz", public: false)

        results = call(q: "el", field: "back", lang: "en")
        expect(results).to include("elephant")
        expect(results).to include("elbow")
      end

      it "applies language filter to definition_language for primary bucket" do
        create(:flashcard, deck: create(:deck, user: other, definition_language: "en"),
               back_content: "elephant", public: true)
        create(:flashcard, deck: create(:deck, user: other, definition_language: "de"),
               back_content: "elefant", public: true)

        results = call(q: "ele", field: "back", lang: "en")
        expect(results).to include("elephant")
        expect(results).not_to include("elefant")
      end
    end
  end
end
