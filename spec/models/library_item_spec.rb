require "rails_helper"

RSpec.describe LibraryItem, type: :model do
  let(:owner)  { create(:user) }
  let(:saver)  { create(:user) }
  let(:deck)   { create(:deck, user: owner, visibility: "public") }

  describe "associations" do
    it "belongs to a user" do
      item = build(:library_item, user: saver, deck: deck)
      expect(item.user).to eq(saver)
    end

    it "belongs to a deck" do
      item = build(:library_item, user: saver, deck: deck)
      expect(item.deck).to eq(deck)
    end
  end

  describe "validations" do
    it "is valid with a user and a deck they do not own" do
      item = build(:library_item, user: saver, deck: deck)
      expect(item).to be_valid
    end

    it "is invalid when the user already has a LibraryItem for the same deck" do
      create(:library_item, user: saver, deck: deck)
      duplicate = build(:library_item, user: saver, deck: deck)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:deck_id]).to be_present
    end

    it "is invalid when the user tries to save their own deck" do
      item = build(:library_item, user: owner, deck: deck)
      expect(item).not_to be_valid
      expect(item.errors[:base]).to be_present
    end

    it "allows different users to each save the same deck" do
      other_saver = create(:user)
      create(:library_item, user: saver, deck: deck)
      item = build(:library_item, user: other_saver, deck: deck)
      expect(item).to be_valid
    end

    it "allows the same user to save different decks" do
      other_deck = create(:deck, user: owner, visibility: "public")
      create(:library_item, user: saver, deck: deck)
      item = build(:library_item, user: saver, deck: other_deck)
      expect(item).to be_valid
    end
  end

  describe "DB-level uniqueness enforcement" do
    it "raises ActiveRecord::RecordNotUnique on duplicate insert bypassing validations" do
      LibraryItem.create!(user: saver, deck: deck)
      duplicate = LibraryItem.new(user: saver, deck: deck)
      duplicate.validate  # skip app-level check
      expect {
        duplicate.save(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "cascade deletion" do
    it "is destroyed when the saver's user account is deleted" do
      item = create(:library_item, user: saver, deck: deck)
      saver.destroy
      expect(LibraryItem.exists?(item.id)).to be false
    end

    it "is destroyed when the saved deck is deleted" do
      item = create(:library_item, user: saver, deck: deck)
      deck.destroy
      expect(LibraryItem.exists?(item.id)).to be false
    end
  end
end
