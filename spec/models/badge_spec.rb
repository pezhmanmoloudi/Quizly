require "rails_helper"

RSpec.describe Badge, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      badge = build(:badge)
      expect(badge).to be_valid
    end

    it "is invalid without key" do
      badge = build(:badge, key: nil)
      expect(badge).not_to be_valid
    end

    it "is invalid without name" do
      badge = build(:badge, name: nil)
      expect(badge).not_to be_valid
    end

    it "is invalid without description" do
      badge = build(:badge, description: nil)
      expect(badge).not_to be_valid
    end

    it "is invalid without icon" do
      badge = build(:badge, icon: nil)
      expect(badge).not_to be_valid
    end

    it "is invalid without category" do
      badge = build(:badge, category: nil)
      expect(badge).not_to be_valid
    end

    it "is invalid with an unrecognized category" do
      badge = build(:badge, category: "unknown")
      expect(badge).not_to be_valid
    end

    it "is valid with category streak" do
      expect(build(:badge, category: "streak")).to be_valid
    end

    it "is valid with category cards" do
      expect(build(:badge, category: "cards")).to be_valid
    end

    it "is valid with category accuracy" do
      expect(build(:badge, category: "accuracy")).to be_valid
    end

    it "rejects a duplicate key" do
      create(:badge, key: "unique_key")
      duplicate = build(:badge, key: "unique_key")
      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it "has many user_badges" do
      association = described_class.reflect_on_association(:user_badges)
      expect(association.macro).to eq(:has_many)
    end

    it "has many users through user_badges" do
      association = described_class.reflect_on_association(:users)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:user_badges)
    end
  end
end
