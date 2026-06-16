require "rails_helper"

RSpec.describe Folders::AssignDeckService do
  let(:user)   { create(:user) }
  let(:deck)   { create(:deck, user: user) }
  let(:folder) { create(:folder, user: user) }

  describe "action: :add" do
    subject(:result) { described_class.call(deck: deck, folder: folder, action: :add) }

    it "creates a DeckFolder join record" do
      expect { result }.to change(DeckFolder, :count).by(1)
    end

    it "returns a successful result" do
      expect(result.ok?).to be true
      expect(result.error).to be_nil
    end

    context "when the deck is already in the folder" do
      before { described_class.call(deck: deck, folder: folder, action: :add) }

      it "does not duplicate the join record" do
        expect { result }.not_to change(DeckFolder, :count)
      end

      it "returns a failure result (uniqueness constraint)" do
        expect(result.ok?).to be false
        expect(result.error).to be_present
      end
    end
  end

  describe "action: :remove" do
    before { described_class.call(deck: deck, folder: folder, action: :add) }

    subject(:result) { described_class.call(deck: deck, folder: folder, action: :remove) }

    it "removes the DeckFolder join record" do
      expect { result }.to change(DeckFolder, :count).by(-1)
    end

    it "returns a successful result" do
      expect(result.ok?).to be true
    end

    context "when the deck is not in the folder" do
      before { described_class.call(deck: deck, folder: folder, action: :remove) }

      it "returns a failure result with :not_in_folder error" do
        expect { result }.not_to change(DeckFolder, :count)
        expect(result.ok?).to be false
        expect(result.error).to eq(:not_in_folder)
      end
    end
  end
end
