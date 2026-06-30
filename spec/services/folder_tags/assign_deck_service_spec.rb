require "rails_helper"

RSpec.describe FolderTags::AssignDeckService do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user) }
  let(:tag)    { create(:folder_tag, folder: folder) }
  let(:deck)   { create(:deck, user: user) }

  describe ".call with :add" do
    it "tags the deck" do
      expect {
        described_class.call(folder_tag: tag, deck: deck, action: :add)
      }.to change(DeckFolderTag, :count).by(1)
    end

    it "returns ok" do
      result = described_class.call(folder_tag: tag, deck: deck, action: :add)
      expect(result.ok?).to be(true)
    end

    it "does not duplicate an existing assignment" do
      create(:deck_folder_tag, folder_tag: tag, deck: deck)
      result = described_class.call(folder_tag: tag, deck: deck, action: :add)
      expect(result.ok?).to be(false)
    end
  end

  describe ".call with :remove" do
    it "removes the tag from the deck" do
      create(:deck_folder_tag, folder_tag: tag, deck: deck)
      expect {
        described_class.call(folder_tag: tag, deck: deck, action: :remove)
      }.to change(DeckFolderTag, :count).by(-1)
    end

    it "returns not_tagged when no assignment exists" do
      result = described_class.call(folder_tag: tag, deck: deck, action: :remove)
      expect(result.error).to eq(:not_tagged)
    end
  end

  describe ".call with an unknown action" do
    it "returns unknown_action" do
      result = described_class.call(folder_tag: tag, deck: deck, action: :sync)
      expect(result.error).to eq(:unknown_action)
    end
  end
end
