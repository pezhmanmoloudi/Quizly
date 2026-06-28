require "rails_helper"

RSpec.describe DeckDuplicator, type: :service do
  let(:owner) { create(:user) }
  let(:copier) { create(:user) }
  let(:source) do
    create(:deck, user: owner, name: "Original", description: "Desc",
           visibility: "public", access_mode: "open")
  end
  let!(:card1) { create(:flashcard, deck: source, front_content: "Hello", back_content: "World", position: 1) }
  let!(:card2) { create(:flashcard, deck: source, front_content: "Foo",   back_content: "Bar",   position: 2) }

  subject(:copy) { described_class.call(source_deck: source, user: copier) }

  describe ".call" do
    it "returns a Deck record" do
      expect(copy).to be_a(Deck)
    end

    it "persists the copy" do
      expect(copy).to be_persisted
    end

    it "assigns the copy to the requesting user" do
      expect(copy.user).to eq(copier)
    end

    it "copies the deck name by default" do
      expect(copy.name).to eq("Original")
    end

    it "copies the description" do
      expect(copy.description).to eq("Desc")
    end

    it "sets source_deck to the original" do
      expect(copy.source_deck).to eq(source)
    end

    it "copies all flashcards" do
      expect(copy.flashcards.count).to eq(2)
    end

    it "preserves flashcard front content" do
      fronts = copy.flashcards.order(:position).pluck(:front_content)
      expect(fronts).to eq(%w[Hello Foo])
    end

    it "preserves flashcard back content" do
      backs = copy.flashcards.order(:position).pluck(:back_content)
      expect(backs).to eq(%w[World Bar])
    end

    it "preserves flashcard positions" do
      positions = copy.flashcards.order(:position).pluck(:position)
      expect(positions).to eq([ 1, 2 ])
    end

    context "with a custom name" do
      subject(:copy) { described_class.call(source_deck: source, user: copier, name: "My Copy") }

      it "uses the custom name" do
        expect(copy.name).to eq("My Copy")
      end
    end

    context "with a valid custom visibility" do
      subject(:copy) { described_class.call(source_deck: source, user: copier, visibility: "public") }

      it "stores the custom visibility" do
        expect(copy.visibility).to eq("public")
      end
    end

    context "with an invalid visibility" do
      subject(:copy) { described_class.call(source_deck: source, user: copier, visibility: "bogus") }

      it "defaults to private" do
        expect(copy.visibility).to eq("private")
      end
    end

    context "with an invalid access_mode" do
      subject(:copy) { described_class.call(source_deck: source, user: copier, access_mode: "bogus") }

      it "defaults to open" do
        expect(copy.access_mode).to eq("open")
      end
    end

    it "does not modify the source deck" do
      expect { copy }.not_to change { source.reload.name }
    end

    it "does not modify the source deck flashcard count" do
      expect { copy }.not_to change { source.flashcards.count }
    end
  end
end
