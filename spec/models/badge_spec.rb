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

  describe "#name and #description" do
    it "translate via the badge key for the current locale" do
      badge = build(:badge, key: "streak_7", name: "Weekly Warrior", description: "Study 7 days in a row")

      I18n.with_locale(:es) do
        expect(badge.name).to eq("Guerrero semanal")
        expect(badge.description).to eq("Estudia 7 días seguidos")
      end
    end

    it "fall back to the stored column when no translation exists for the key" do
      badge = build(:badge, key: "no_such_badge_key", name: "Custom Name", description: "Custom desc")

      expect(badge.name).to eq("Custom Name")
      expect(badge.description).to eq("Custom desc")
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
