require "rails_helper"

RSpec.describe Folder, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "is valid with valid attributes" do
      folder = build(:folder, user: user)
      expect(folder).to be_valid
    end

    it "is invalid without name" do
      folder = build(:folder, user: user, name: nil)
      expect(folder).not_to be_valid
    end

    it "is invalid with a name longer than 60 characters" do
      folder = build(:folder, user: user, name: "a" * 61)
      expect(folder).not_to be_valid
    end

    it "is valid with a name exactly 60 characters" do
      folder = build(:folder, user: user, name: "a" * 60)
      expect(folder).to be_valid
    end

    it "is invalid with an unrecognized kind" do
      folder = build(:folder, user: user, kind: "bogus")
      expect(folder).not_to be_valid
    end

    Folder::KIND_VALUES.each do |kind|
      it "is valid with kind #{kind}" do
        expect(build(:folder, user: user, kind: kind)).to be_valid
      end
    end
  end

  describe "associations" do
    it "belongs to user" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many deck_folders" do
      association = described_class.reflect_on_association(:deck_folders)
      expect(association.macro).to eq(:has_many)
    end

    it "has many decks through deck_folders" do
      association = described_class.reflect_on_association(:decks)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:deck_folders)
    end
  end
end
