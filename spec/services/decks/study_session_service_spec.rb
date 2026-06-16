require "rails_helper"

RSpec.describe Decks::StudySessionService do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, :public, user: create(:user)) }

  describe ".find_or_create" do
    subject(:result) do
      described_class.find_or_create(
        deck:       deck,
        user:       user,
        session_id: session_id,
        due_count:  due_count
      )
    end

    let(:due_count) { 5 }

    context "when session_id is nil" do
      let(:session_id) { nil }

      it "creates a new StudySession" do
        expect { result }.to change(StudySession, :count).by(1)
      end

      it "stores the due_count as cards_total" do
        expect(result.cards_total).to eq(5)
      end

      it "links to the correct deck and user" do
        expect(result.deck).to eq(deck)
        expect(result.user).to eq(user)
      end
    end

    context "when session_id points to an active session" do
      let!(:existing) do
        described_class.find_or_create(deck: deck, user: user, session_id: nil, due_count: 3)
      end
      let(:session_id) { existing.id }

      it "reuses the existing session" do
        expect { result }.not_to change(StudySession, :count)
      end

      context "when due_count has grown" do
        let(:due_count) { 10 }

        it "updates cards_total upward" do
          expect(result.cards_total).to eq(10)
        end
      end

      context "when due_count is smaller (cards were reviewed)" do
        let(:due_count) { 1 }

        it "does not decrease cards_total" do
          expect(result.cards_total).to eq(3)
        end
      end
    end

    context "when session_id points to a finished session" do
      let!(:finished) do
        s = described_class.find_or_create(deck: deck, user: user, session_id: nil, due_count: 3)
        s.update!(finished_at: Time.current)
        s
      end
      let(:session_id) { finished.id }

      it "creates a new session" do
        expect { result }.to change(StudySession, :count).by(1)
      end
    end
  end
end
