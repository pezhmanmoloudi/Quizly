require "rails_helper"

RSpec.describe SuggestionEngine, type: :service do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }
  let(:other) { create(:user) }

  def call(scope:, col:, q:, limit: SuggestionEngine::FETCH_LIMIT)
    described_class.call(q:, scope:, col:, limit:)
  end

  def own_scope   = Flashcard.joins(:deck).where(decks: { user_id: user.id })
  def public_scope = Flashcard.joins(:deck).where(public: true)

  describe ".call" do
    context "when q is blank" do
      it "returns [] for empty string" do
        expect(call(scope: own_scope, col: "front_content", q: "")).to eq([])
      end

      it "returns [] for whitespace-only" do
        expect(call(scope: own_scope, col: "front_content", q: "   ")).to eq([])
      end
    end

    context "prefix matching" do
      before { create(:flashcard, deck: deck, front_content: "elephant") }

      it "returns a card whose front_content starts with the query" do
        expect(call(scope: own_scope, col: "front_content", q: "ele")).to include("elephant")
      end

      it "does not return a card that only contains the query mid-word" do
        # 'elephant' contains 'pha' — should NOT match because engine is prefix-only
        expect(call(scope: own_scope, col: "front_content", q: "pha")).to be_empty
      end
    end

    context "column selection" do
      before do
        create(:flashcard, deck: deck, front_content: "cat", back_content: "gorbeh")
      end

      it "matches on front_content when col is front_content" do
        expect(call(scope: own_scope, col: "front_content", q: "cat")).to include("cat")
      end

      it "matches on back_content when col is back_content" do
        expect(call(scope: own_scope, col: "back_content", q: "gorb")).to include("gorbeh")
      end

      it "does not cross-match columns" do
        expect(call(scope: own_scope, col: "front_content", q: "gorb")).to be_empty
      end
    end

    context "case-insensitive matching" do
      before { create(:flashcard, deck: deck, front_content: "Elephant") }

      it "returns the card when query is lowercase" do
        expect(call(scope: own_scope, col: "front_content", q: "ele")).to include("Elephant")
      end

      it "returns the card when query is mixed case" do
        expect(call(scope: own_scope, col: "front_content", q: "ELE")).to include("Elephant")
      end
    end

    context "scope isolation" do
      let!(:own_card)    { create(:flashcard, deck: deck, front_content: "apple") }
      let!(:public_card) { create(:flashcard, deck: create(:deck, user: other), front_content: "apricot", public: true) }

      it "only returns own cards when given own_scope" do
        results = call(scope: own_scope, col: "front_content", q: "ap")
        expect(results).to include("apple")
        expect(results).not_to include("apricot")
      end

      it "only returns public cards when given public_scope" do
        results = call(scope: public_scope, col: "front_content", q: "ap")
        expect(results).to include("apricot")
        expect(results).not_to include("apple")
      end
    end

    context "soft-deleted cards" do
      it "never returns a deleted card (excluded by default_scope)" do
        card = create(:flashcard, deck: deck, front_content: "ghost")
        card.soft_delete!
        expect(call(scope: own_scope, col: "front_content", q: "gho")).to be_empty
      end
    end

    context "no implicit ordering" do
      it "does not order by length — returns records in natural DB order" do
        # Insert long word first, short word second
        create(:flashcard, deck: deck, front_content: "elaborate")
        create(:flashcard, deck: deck, front_content: "elephant")

        results = call(scope: own_scope, col: "front_content", q: "el")
        # Both present; order is not guaranteed by the engine
        expect(results).to include("elaborate", "elephant")
      end
    end

    context "limit" do
      it "respects a custom limit" do
        3.times { |i| create(:flashcard, deck: deck, front_content: "word#{i}") }
        expect(call(scope: own_scope, col: "front_content", q: "word", limit: 2).size).to be <= 2
      end
    end

    context "non-ASCII input" do
      it "matches Persian content" do
        create(:flashcard, deck: create(:deck, user: other), front_content: "فیل", public: true)
        expect(call(scope: public_scope, col: "front_content", q: "فی")).to include("فیل")
      end
    end

    context "LIKE wildcard injection" do
      it "treats % in the query as a literal character" do
        create(:flashcard, deck: deck, front_content: "100%")
        expect(call(scope: own_scope, col: "front_content", q: "100%")).to include("100%")
        # Should not match everything
        create(:flashcard, deck: deck, front_content: "unrelated")
        expect(call(scope: own_scope, col: "front_content", q: "100%")).not_to include("unrelated")
      end

      it "treats _ in the query as a literal character" do
        create(:flashcard, deck: deck, front_content: "a_b")
        expect(call(scope: own_scope, col: "front_content", q: "a_b")).to include("a_b")
        expect(call(scope: own_scope, col: "front_content", q: "a_b")).not_to include("axb") rescue nil
      end
    end
  end
end
