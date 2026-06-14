require "rails_helper"

RSpec.describe Deck, type: :model do
  describe "scopes" do
    it ".discoverable includes public decks" do
      create(:deck, :public)
      expect(Deck.discoverable.map(&:visibility)).to include("public")
    end

    it ".discoverable excludes private decks" do
      create(:deck, :private)
      create(:deck, :public)
      expect(Deck.discoverable.map(&:visibility)).not_to include("private")
    end

    it ".discoverable excludes unlisted decks" do
      create(:deck, :unlisted)
      create(:deck, :public)
      expect(Deck.discoverable.map(&:visibility)).not_to include("unlisted")
    end

    it ".discoverable excludes both unlisted and private decks" do
      create(:deck, :unlisted)
      create(:deck, :private)
      create(:deck, :public)
      result = Deck.discoverable.map(&:visibility)
      expect(result).not_to include("unlisted")
      expect(result).not_to include("private")
    end
  end

  describe "#preview_accessible?" do
    it "is true for public decks" do
      expect(build(:deck, :public).preview_accessible?).to be true
    end

    it "is false for private decks" do
      expect(build(:deck, :private).preview_accessible?).to be false
    end

    it "is false for unlisted decks" do
      expect(build(:deck, :unlisted).preview_accessible?).to be false
    end
  end

  describe "associations" do
    it "belongs to a user" do
      deck = build(:deck)
      expect(deck.user).to be_present
    end

    it "has many flashcards" do
      assoc = described_class.reflect_on_association(:flashcards)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "is valid with a name, optional description, and optional language_code" do
      deck = build(:deck, name: "Spanish Vocab", description: "Common words", language_code: "es")
      expect(deck).to be_valid
    end

    it "is valid without a description" do
      deck = build(:deck, description: nil)
      expect(deck).to be_valid
    end

    it "is valid without a language_code" do
      deck = build(:deck, language_code: nil)
      expect(deck).to be_valid
    end

    it "is invalid without a name" do
      deck = build(:deck, name: "")
      expect(deck).not_to be_valid
      expect(deck.errors[:name]).to include("can't be blank")
    end

    it "is invalid with a name longer than 100 characters" do
      deck = build(:deck, name: "A" * 101)
      expect(deck).not_to be_valid
      expect(deck.errors[:name]).to include("is too long (maximum is 100 characters)")
    end

    it "is valid with a name of exactly 100 characters" do
      deck = build(:deck, name: "A" * 100)
      expect(deck).to be_valid
    end

    it "rejects an unsupported visibility value" do
      deck = build(:deck, visibility: "secret")
      expect(deck).not_to be_valid
    end

    it "rejects an unsupported edit_permission value" do
      deck = build(:deck, edit_permission: "admin_only")
      expect(deck).not_to be_valid
    end

    it "rejects private + people_with_password combination" do
      deck = build(:deck, visibility: "private", edit_permission: "people_with_password",
                          password: "secret123")
      expect(deck).not_to be_valid
      expect(deck.errors[:edit_permission]).to be_present
    end

    it "allows unlisted + people_with_password combination" do
      deck = build(:deck, visibility: "unlisted", edit_permission: "people_with_password",
                          password: "secret123")
      expect(deck).to be_valid
    end

    it "is valid with unlisted + only_me" do
      deck = build(:deck, visibility: "unlisted", edit_permission: "only_me")
      expect(deck).to be_valid
    end

    it "requires password when edit_permission is people_with_password" do
      deck = build(:deck, edit_permission: "people_with_password", password: nil)
      expect(deck).not_to be_valid
      expect(deck.errors[:password]).to be_present
    end

    it "does not require password for private + only_me" do
      deck = build(:deck, visibility: "private", edit_permission: "only_me", password: nil)
      expect(deck).to be_valid
    end

    it "does not require password for public + only_me" do
      deck = build(:deck, visibility: "public", edit_permission: "only_me", password: nil)
      expect(deck).to be_valid
    end

    it "rejects password shorter than 8 characters" do
      deck = build(:deck, edit_permission: "people_with_password", password: "short")
      expect(deck).not_to be_valid
      expect(deck.errors[:password]).to be_present
    end

    it "rejects password longer than 128 characters" do
      deck = build(:deck, edit_permission: "people_with_password", password: "a" * 129)
      expect(deck).not_to be_valid
      expect(deck.errors[:password]).to be_present
    end

    it "is valid with password of exactly 8 characters" do
      deck = build(:deck, visibility: "public", edit_permission: "people_with_password", password: "a" * 8)
      expect(deck).to be_valid
    end
  end

  describe "visibility predicates" do
    it "defaults to public" do
      deck = Deck.new(name: "Test", user: build(:user))
      expect(deck.visibility).to eq("public")
    end

    it "#public? is true when visibility is public" do
      expect(build(:deck, visibility: "public").public?).to be true
    end

    it "#private? is true when visibility is private" do
      expect(build(:deck, visibility: "private").private?).to be true
    end

    it "#unlisted? is true when visibility is unlisted" do
      expect(build(:deck, visibility: "unlisted").unlisted?).to be true
    end
  end

  describe "#can_view?" do
    let(:owner) { build(:user, id: 1) }
    let(:other)  { build(:user, id: 2) }

    context "visibility: public" do
      let(:deck) { build(:deck, user: owner, visibility: "public") }

      it "allows nil user" do
        expect(deck.can_view?(nil)).to be true
      end

      it "allows authenticated non-owner" do
        expect(deck.can_view?(other)).to be true
      end

      it "allows owner" do
        expect(deck.can_view?(owner)).to be true
      end
    end

    context "visibility: private" do
      let(:deck) { build(:deck, user: owner, visibility: "private") }

      it "denies nil user" do
        expect(deck.can_view?(nil)).to be false
      end

      it "denies non-owner" do
        expect(deck.can_view?(other)).to be false
      end

      it "denies non-owner even when unlocked" do
        deck.unlocked = true
        expect(deck.can_view?(other)).to be false
      end

      it "allows owner" do
        expect(deck.can_view?(owner)).to be true
      end
    end

    context "visibility: unlisted without password" do
      let(:deck) { build(:deck, user: owner, visibility: "unlisted") }

      it "allows nil user (no password set)" do
        expect(deck.can_view?(nil)).to be true
      end

      it "allows non-owner (no password set)" do
        expect(deck.can_view?(other)).to be true
      end

      it "allows owner" do
        expect(deck.can_view?(owner)).to be true
      end
    end

    context "visibility: unlisted with password" do
      let(:deck) { build(:deck, user: owner, visibility: "unlisted", edit_permission: "people_with_password", password: "secret123") }

      it "denies nil user without unlock" do
        expect(deck.can_view?(nil)).to be false
      end

      it "denies non-owner without unlock" do
        expect(deck.can_view?(other)).to be false
      end

      it "allows nil user when unlocked" do
        deck.unlocked = true
        expect(deck.can_view?(nil)).to be true
      end

      it "allows non-owner when unlocked" do
        deck.unlocked = true
        expect(deck.can_view?(other)).to be true
      end

      it "allows owner without unlock" do
        expect(deck.can_view?(owner)).to be true
      end
    end
  end

  describe "#can_edit?" do
    let(:owner) { build(:user, id: 1) }
    let(:other)  { build(:user, id: 2) }

    context "edit_permission: only_me" do
      let(:deck) { build(:deck, user: owner, edit_permission: "only_me") }

      it "denies nil user" do
        expect(deck.can_edit?(nil)).to be false
      end

      it "denies non-owner" do
        expect(deck.can_edit?(other)).to be false
      end

      it "denies non-owner even when unlocked" do
        deck.unlocked = true
        expect(deck.can_edit?(other)).to be false
      end

      it "allows owner" do
        expect(deck.can_edit?(owner)).to be true
      end
    end

    context "edit_permission: people_with_password" do
      let(:deck) { build(:deck, user: owner, visibility: "public", edit_permission: "people_with_password") }

      it "denies nil user even when unlocked" do
        deck.unlocked = true
        expect(deck.can_edit?(nil)).to be false
      end

      it "denies non-owner without unlock" do
        expect(deck.can_edit?(other)).to be false
      end

      it "allows non-owner when unlocked" do
        deck.unlocked = true
        expect(deck.can_edit?(other)).to be true
      end

      it "allows owner regardless of unlock" do
        expect(deck.can_edit?(owner)).to be true
      end
    end

    context "visibility: private" do
      let(:deck) { build(:deck, user: owner, visibility: "private", edit_permission: "only_me") }

      it "denies non-owner even when unlocked" do
        deck.unlocked = true
        expect(deck.can_edit?(other)).to be false
      end
    end
  end

  describe "#can_edit_settings?" do
    let(:owner) { build(:user, id: 1) }
    let(:other)  { build(:user, id: 2) }
    let(:deck)   { build(:deck, user: owner) }

    it "allows owner" do
      expect(deck.can_edit_settings?(owner)).to be true
    end

    it "denies non-owner" do
      expect(deck.can_edit_settings?(other)).to be false
    end

    it "denies nil" do
      expect(deck.can_edit_settings?(nil)).to be false
    end

    it "denies password user (admin domain is owner-only)" do
      pw_deck = build(:deck, :editable_by_password, user: owner)
      expect(pw_deck.can_edit_settings?(other)).to be false
    end
  end

  describe "#can_delete?" do
    let(:owner) { build(:user, id: 1) }
    let(:other)  { build(:user, id: 2) }
    let(:deck)   { build(:deck, user: owner) }

    it "allows owner" do
      expect(deck.can_delete?(owner)).to be true
    end

    it "denies non-owner" do
      expect(deck.can_delete?(other)).to be false
    end

    it "denies nil" do
      expect(deck.can_delete?(nil)).to be false
    end
  end

  describe "#tag_list" do
    it "returns an empty array when subject_tags is nil" do
      deck = build(:deck, subject_tags: nil)
      expect(deck.tag_list).to eq([])
    end

    it "parses comma-separated tags into an array" do
      deck = build(:deck, subject_tags: "biology, anatomy, exam2025")
      expect(deck.tag_list).to eq(%w[biology anatomy exam2025])
    end

    it "ignores blank entries" do
      deck = build(:deck, subject_tags: "biology,,  ")
      expect(deck.tag_list).to eq(["biology"])
    end
  end

  describe "#tag_list=" do
    it "normalises and stores tags as a comma-separated string" do
      deck = build(:deck)
      deck.tag_list = "Biology,  anatomy , EXAM2025"
      expect(deck.subject_tags).to eq("Biology, anatomy, EXAM2025")
    end
  end

  describe "dependent destruction" do
    it "destroys associated flashcards when the deck is deleted" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      expect { deck.destroy }.to change(Flashcard, :count).by(-1)
    end
  end
end
