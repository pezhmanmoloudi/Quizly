require "rails_helper"

RSpec.describe FolderTag, type: :model do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:folder_tag, folder: folder, name: "Grammar")).to be_valid
    end

    it "requires a name" do
      expect(build(:folder_tag, folder: folder, name: "")).not_to be_valid
    end

    it "rejects names longer than 60 characters" do
      expect(build(:folder_tag, folder: folder, name: "a" * 61)).not_to be_valid
    end

    it "rejects a duplicate name within the same folder (case-insensitive)" do
      create(:folder_tag, folder: folder, name: "Grammar")
      expect(build(:folder_tag, folder: folder, name: "grammar")).not_to be_valid
    end

    it "allows the same name in a different folder" do
      other_folder = create(:folder, user: user)
      create(:folder_tag, folder: folder, name: "Grammar")
      expect(build(:folder_tag, folder: other_folder, name: "Grammar")).to be_valid
    end
  end

  describe "color" do
    it "assigns a palette color on creation" do
      tag = create(:folder_tag, folder: folder)
      expect(FolderTag::COLORS).to include(tag.color)
    end

    it "keeps an explicitly provided color" do
      tag = create(:folder_tag, folder: folder, color: "#123456")
      expect(tag.color).to eq("#123456")
    end
  end

  describe "associations" do
    it "belongs to a folder" do
      expect(described_class.reflect_on_association(:folder).macro).to eq(:belongs_to)
    end

    it "has many decks through deck_folder_tags" do
      tag  = create(:folder_tag, folder: folder)
      deck = create(:deck, user: user)
      create(:deck_folder_tag, folder_tag: tag, deck: deck)
      expect(tag.decks).to include(deck)
    end

    it "destroys its deck_folder_tags when destroyed" do
      tag  = create(:folder_tag, folder: folder)
      deck = create(:deck, user: user)
      create(:deck_folder_tag, folder_tag: tag, deck: deck)
      expect { tag.destroy }.to change(DeckFolderTag, :count).by(-1)
    end
  end
end
