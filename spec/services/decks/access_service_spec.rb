require "rails_helper"

RSpec.describe Decks::AccessService do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }

  # ── .evaluate ─────────────────────────────────────────────────────────────

  describe ".evaluate" do
    subject(:result) { described_class.evaluate(deck: deck, user: user, session: sess) }

    let(:sess) { {} }

    context "public open deck" do
      let(:deck) { create(:deck, :public, user: owner) }

      context "as owner" do
        let(:user) { owner }
        it { is_expected.to be_allowed }
        it { is_expected.to be_owner }
        it { is_expected.not_to be_requires_password }
        it { is_expected.not_to be_locked }
      end

      context "as authenticated non-owner" do
        let(:user) { other }
        it { is_expected.to be_allowed }
        it { is_expected.not_to be_owner }
        it { is_expected.not_to be_locked }
      end

      context "as guest (nil user)" do
        let(:user) { nil }
        it { is_expected.to be_allowed }
        it { is_expected.not_to be_owner }
      end
    end

    context "public password-protected deck" do
      let(:deck) { create(:deck, :password_protected, user: owner) }

      context "as owner" do
        let(:user) { owner }
        it "is allowed (owner bypass)" do
          is_expected.to be_allowed
        end
        it { is_expected.to be_owner }
        it "marks deck as requiring a password" do
          is_expected.to be_requires_password
        end
        it { is_expected.not_to be_locked }
      end

      context "as non-owner without session flag" do
        let(:user) { other }
        it { is_expected.to be_locked }
        it { is_expected.not_to be_allowed }
      end

      context "as guest without session flag" do
        let(:user) { nil }
        it { is_expected.to be_locked }
      end

      context "as non-owner with session flag set" do
        let(:user) { other }
        let(:sess) { { "deck_#{deck.id}_unlocked" => true } }
        it { is_expected.to be_allowed }
        it "still marks deck as requiring a password (deck attribute, not user state)" do
          is_expected.to be_requires_password
        end
      end

      context "as guest with session flag set" do
        let(:user) { nil }
        let(:sess) { { "deck_#{deck.id}_unlocked" => true } }
        it { is_expected.to be_allowed }
      end
    end

    context "unlisted open deck" do
      let(:deck) { create(:deck, :unlisted, user: owner) }

      context "as guest" do
        let(:user) { nil }
        it { is_expected.to be_allowed }
      end

      context "as non-owner" do
        let(:user) { other }
        it { is_expected.to be_allowed }
      end
    end

    context "private open deck" do
      let(:deck) { create(:deck, :private, user: owner) }

      context "as owner" do
        let(:user) { owner }
        it { is_expected.to be_allowed }
        it { is_expected.to be_owner }
      end

      context "as non-owner" do
        let(:user) { other }
        it { is_expected.to be_denied }
        it { is_expected.not_to be_allowed }
      end

      context "as guest" do
        let(:user) { nil }
        it { is_expected.to be_denied }
      end
    end
  end

  # ── .call (perform_unlock) ─────────────────────────────────────────────────

  describe ".call" do
    let(:deck)    { create(:deck, :password_protected) }
    let(:session) { {} }

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

    context "when the deck is not password-protected" do
      let(:deck) { create(:deck, :public) }

      it "returns a failure (no password to match)" do
        result = described_class.call(deck: deck, password: nil, session: session)
        expect(result.ok?).to be false
      end
    end
  end

  # ── .unlocked? ────────────────────────────────────────────────────────────

  describe ".unlocked?" do
    let(:deck)    { create(:deck, :password_protected) }
    let(:session) { {} }

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
end
