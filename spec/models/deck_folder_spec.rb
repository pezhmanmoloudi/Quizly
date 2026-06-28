require "rails_helper"

RSpec.describe DeckFolder, type: :model do
  let(:user)   { create(:user) }
  let(:deck)   { create(:deck, user: user) }
  let(:folder) { create(:folder, user: user) }

  describe "validations" do
    it "is valid with valid attributes" do
      deck_folder = build(:deck_folder, deck: deck, folder: folder)
      expect(deck_folder).to be_valid
    end

    it "rejects the same deck added twice to the same folder" do
      create(:deck_folder, deck: deck, folder: folder)
      duplicate = build(:deck_folder, deck: deck, folder: folder)
      expect(duplicate).not_to be_valid
    end

    it "allows the same deck in different folders" do
      other_folder = create(:folder, user: user)
      create(:deck_folder, deck: deck, folder: folder)
      second = build(:deck_folder, deck: deck, folder: other_folder)
      expect(second).to be_valid
    end

    it "allows different decks in the same folder" do
      other_deck = create(:deck, user: user)
      create(:deck_folder, deck: deck, folder: folder)
      second = build(:deck_folder, deck: other_deck, folder: folder)
      expect(second).to be_valid
    end
  end

  describe "associations" do
    it "belongs to deck" do
      association = described_class.reflect_on_association(:deck)
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to folder" do
      association = described_class.reflect_on_association(:folder)
      expect(association.macro).to eq(:belongs_to)
    end
  end
end
