require "rails_helper"

RSpec.describe DeckFolderTag, type: :model do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:tag)    { create(:folder_tag, folder: folder) }
  let(:deck)   { create(:deck, user: user) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:deck_folder_tag, folder_tag: tag, deck: deck)).to be_valid
    end

    it "rejects the same deck tagged twice with the same tag" do
      create(:deck_folder_tag, folder_tag: tag, deck: deck)
      expect(build(:deck_folder_tag, folder_tag: tag, deck: deck)).not_to be_valid
    end

    it "allows the same deck under different tags" do
      other_tag = create(:folder_tag, folder: folder)
      create(:deck_folder_tag, folder_tag: tag, deck: deck)
      expect(build(:deck_folder_tag, folder_tag: other_tag, deck: deck)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a folder_tag" do
      expect(described_class.reflect_on_association(:folder_tag).macro).to eq(:belongs_to)
    end

    it "belongs to a deck" do
      expect(described_class.reflect_on_association(:deck).macro).to eq(:belongs_to)
    end
  end
end
