require "rails_helper"

RSpec.describe Decks::CreationService, type: :service do
  let(:user) { create(:user) }

  describe ".call" do
    subject(:deck) { described_class.call(user: user, name: "My Deck") }

    it "returns a Deck record" do
      expect(deck).to be_a(Deck)
    end

    it "persists the deck" do
      expect(deck).to be_persisted
    end

    it "assigns the deck to the given user" do
      expect(deck.user).to eq(user)
    end

    it "uses the provided name" do
      expect(deck.name).to eq("My Deck")
    end

    it "sets visibility to private" do
      expect(deck.visibility).to eq("private")
    end

    it "sets access_mode to open" do
      expect(deck.access_mode).to eq("open")
    end

    it "increments the user's deck count" do
      expect { deck }.to change { user.decks.count }.by(1)
    end
  end
end
