require "rails_helper"

RSpec.describe Decks::TestSessionService do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: create(:user)) }

  def create_cards(n)
    n.times { create(:flashcard, deck: deck) }
    deck.flashcards.to_a
  end

  describe ".find_or_create" do
    subject(:result) do
      described_class.find_or_create(
        deck:       deck,
        user:       user,
        session_id: session_id,
        flashcards: flashcards
      )
    end

    context "when session_id is nil" do
      let(:session_id) { nil }
      let(:flashcards) { create_cards(3) }

      it "creates a new TestSession" do
        expect { result }.to change(TestSession, :count).by(1)
      end

      it "generates questions for all provided flashcards" do
        expect(result.questions_total).to eq(3)
      end
    end

    context "when deck has more than 20 flashcards" do
      let(:session_id) { nil }
      let(:flashcards) { create_cards(25) }

      it "caps questions at 20" do
        expect(result.questions_total).to eq(20)
      end
    end

    context "when session_id points to an active existing session" do
      let(:flashcards) { create_cards(3) }
      let!(:existing) do
        described_class.find_or_create(deck: deck, user: user, session_id: nil, flashcards: flashcards)
      end
      let(:session_id) { existing.id }

      it "reuses the existing session" do
        expect { result }.not_to change(TestSession, :count)
      end

      it "returns the same session" do
        expect(result.id).to eq(existing.id)
      end
    end

    context "when session_id points to a finished session" do
      let(:flashcards) { create_cards(3) }
      let!(:finished) do
        s = described_class.find_or_create(deck: deck, user: user, session_id: nil, flashcards: flashcards)
        s.update!(finished_at: Time.current)
        s
      end
      let(:session_id) { finished.id }

      it "creates a new session" do
        expect { result }.to change(TestSession, :count).by(1)
      end
    end
  end
end
