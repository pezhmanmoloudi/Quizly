require "rails_helper"

RSpec.describe Decks::LearnSessionService do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, :public, user: create(:user)) }

  describe ".find_or_create" do
    subject(:result) do
      described_class.find_or_create(deck: deck, user: user, session_id: session_id)
    end

    context "when session_id is nil" do
      let(:session_id) { nil }

      it "creates a new LearnSession" do
        expect { result }.to change(LearnSession, :count).by(1)
      end

      it "returns the new session" do
        expect(result).to be_a(LearnSession)
        expect(result.deck).to eq(deck)
        expect(result.user).to eq(user)
      end
    end

    context "when session_id points to an active existing session" do
      let(:session_id) { nil }
      let!(:existing) do
        described_class.find_or_create(deck: deck, user: user, session_id: nil)
      end

      it "reuses the existing session" do
        expect {
          described_class.find_or_create(deck: deck, user: user, session_id: existing.id)
        }.not_to change(LearnSession, :count)
      end

      it "returns the same session object" do
        found = described_class.find_or_create(deck: deck, user: user, session_id: existing.id)
        expect(found.id).to eq(existing.id)
      end
    end

    context "when session_id points to a finished session" do
      let!(:finished) do
        s = described_class.find_or_create(deck: deck, user: user, session_id: nil)
        s.update!(finished_at: Time.current)
        s
      end
      let(:session_id) { finished.id }

      it "creates a new session (finished sessions are not reused)" do
        expect { result }.to change(LearnSession, :count).by(1)
      end
    end

    context "when session_id belongs to a different deck" do
      let(:other_deck)  { create(:deck, :public, user: create(:user)) }
      let!(:other_sess) { described_class.find_or_create(deck: other_deck, user: user, session_id: nil) }
      let(:session_id)  { other_sess.id }

      it "creates a new session for the correct deck" do
        expect { result }.to change(LearnSession, :count).by(1)
        expect(result.deck).to eq(deck)
      end
    end
  end
end
