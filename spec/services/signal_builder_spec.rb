require "rails_helper"

RSpec.describe SignalBuilder, type: :service do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }
  let(:other) { create(:user) }

  def call(q:, field: "front", lang: "")
    described_class.call(q:, user:, field:, lang:)
  end

  describe ".call" do
    context "return shape" do
      before { create(:flashcard, deck: deck, front_content: "elephant") }

      it "returns an array of hashes with :value and :source keys" do
        results = call(q: "ele")
        expect(results).to all(include(:value, :source))
      end

      it "returns :value as a String" do
        results = call(q: "ele")
        expect(results.map { |r| r[:value] }).to all(be_a(String))
      end

      it "returns :source as a Symbol from the known set" do
        results = call(q: "ele")
        valid_sources = %i[own_primary public_primary own_opposite public_opposite]
        expect(results.map { |r| r[:source] }).to all(be_in(valid_sources))
      end
    end

    context "source tagging — own_primary" do
      before { create(:flashcard, deck: deck, front_content: "elephant") }

      it "tags own primary-field matches as :own_primary" do
        results = call(q: "ele", lang: "en")
        own = results.select { |r| r[:source] == :own_primary }
        expect(own.map { |r| r[:value] }).to include("elephant")
      end
    end

    context "source tagging — public_primary" do
      before do
        create(:flashcard,
               deck: create(:deck, user: other, term_language: "en"),
               front_content: "elaborate",
               public: true)
      end

      it "tags public primary-field matches as :public_primary" do
        results = call(q: "ela", lang: "en")
        pub = results.select { |r| r[:source] == :public_primary }
        expect(pub.map { |r| r[:value] }).to include("elaborate")
      end

      it "does not include private cards from other users" do
        create(:flashcard,
               deck: create(:deck, user: other),
               front_content: "element",
               public: false)

        values = call(q: "ele").map { |r| r[:value] }
        expect(values).not_to include("element")
      end
    end

    context "source tagging — own_opposite" do
      before do
        create(:flashcard, deck: deck, front_content: "xyz_no_match", back_content: "elephant")
      end

      it "tags own opposite-field matches as :own_opposite" do
        results = call(q: "ele", field: "front")
        opp = results.select { |r| r[:source] == :own_opposite }
        expect(opp.map { |r| r[:value] }).to include("elephant")
      end

      it "does not apply language filter to opposite-field bucket" do
        create(:flashcard, deck: deck,
               front_content: "abc_no_match", back_content: "elaborate")

        values = call(q: "ela", field: "front", lang: "en").map { |r| r[:value] }
        expect(values).to include("elaborate")
      end
    end

    context "source tagging — public_opposite" do
      before do
        create(:flashcard,
               deck: create(:deck, user: other),
               front_content: "xyz_no_match",
               back_content: "elephant",
               public: true)
      end

      it "tags public opposite-field matches as :public_opposite" do
        results = call(q: "ele", field: "front")
        opp = results.select { |r| r[:source] == :public_opposite }
        expect(opp.map { |r| r[:value] }).to include("elephant")
      end
    end

    context "field: back" do
      it "treats back_content as primary and front_content as opposite" do
        create(:flashcard, deck: deck, back_content: "elephant")
        create(:flashcard, deck: deck, front_content: "elbow", back_content: "xyz")

        results   = call(q: "el", field: "back", lang: "en")
        primaries = results.select { |r| r[:source] == :own_primary }.map { |r| r[:value] }
        opposites = results.select { |r| r[:source] == :own_opposite }.map { |r| r[:value] }

        expect(primaries).to include("elephant")
        expect(opposites).to include("elbow")
      end
    end

    context "language filtering" do
      before do
        create(:flashcard, deck: create(:deck, user: other, term_language: "en"),
               front_content: "elephant", public: true)
        create(:flashcard, deck: create(:deck, user: other, term_language: "de"),
               front_content: "elefant", public: true)
      end

      it "restricts primary-field results to the requested language" do
        values = call(q: "ele", field: "front", lang: "en").map { |r| r[:value] }
        expect(values).to include("elephant")
        expect(values).not_to include("elefant")
      end

      it "returns all languages when lang is blank" do
        values = call(q: "ele", field: "front", lang: "").map { |r| r[:value] }
        expect(values).to include("elephant")
        expect(values).to include("elefant")
      end
    end

    context "no scoring" do
      it "does not attach a :score key to any entry" do
        create(:flashcard, deck: deck, front_content: "apple")
        results = call(q: "ap")
        expect(results.any? { |r| r.key?(:score) }).to be false
      end
    end

    context "no ordering" do
      it "does not sort results by length or any other criterion" do
        create(:flashcard, deck: deck, front_content: "elaborate")
        create(:flashcard, deck: deck, front_content: "elephant")

        # Both must appear; order is not the engine's concern
        values = call(q: "el").map { |r| r[:value] }
        expect(values).to include("elaborate", "elephant")
      end
    end
  end
end
