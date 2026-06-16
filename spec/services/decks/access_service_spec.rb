require "rails_helper"

RSpec.describe Decks::AccessService do
  let(:deck) { create(:deck, :password_protected) }
  let(:session) { {} }

  describe ".unlocked?" do
    it "returns true when session flag is set" do
      session["deck_#{deck.id}_unlocked"] = true
      expect(described_class.unlocked?(deck: deck, session: session)).to be true
    end

    it "returns false when session flag is absent" do
      expect(described_class.unlocked?(deck: deck, session: session)).to be false
    end

    it "returns false when session flag is a truthy non-boolean" do
      session["deck_#{deck.id}_unlocked"] = "yes"
      expect(described_class.unlocked?(deck: deck, session: session)).to be false
    end
  end

  describe ".call" do
    context "when the deck is not password-protected" do
      let(:deck) { create(:deck, :public) }

      it "returns a successful result without touching the session" do
        result = described_class.call(deck: deck, password: nil, session: session)
        expect(result.ok?).to be true
        expect(result.error).to be_nil
        expect(session).to be_empty
      end
    end

    context "when the deck is already unlocked in the session" do
      before { session["deck_#{deck.id}_unlocked"] = true }

      it "returns ok without re-authenticating" do
        result = described_class.call(deck: deck, password: "wrongpassword", session: session)
        expect(result.ok?).to be true
      end
    end

    context "with the correct password" do
      it "sets the session unlock flag" do
        described_class.call(deck: deck, password: "secret123", session: session)
        expect(session["deck_#{deck.id}_unlocked"]).to be true
      end

      it "returns a successful result" do
        result = described_class.call(deck: deck, password: "secret123", session: session)
        expect(result.ok?).to be true
        expect(result.error).to be_nil
      end
    end

    context "with an incorrect password" do
      it "does not set the session flag" do
        described_class.call(deck: deck, password: "wrongpass", session: session)
        expect(session["deck_#{deck.id}_unlocked"]).not_to be true
      end

      it "returns a failure result with :invalid_password error" do
        result = described_class.call(deck: deck, password: "wrongpass", session: session)
        expect(result.ok?).to be false
        expect(result.error).to eq(:invalid_password)
      end
    end

    context "with a blank password" do
      it "returns a failure result" do
        result = described_class.call(deck: deck, password: "", session: session)
        expect(result.ok?).to be false
        expect(result.error).to eq(:invalid_password)
      end
    end
  end
end
