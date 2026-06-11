require "rails_helper"

RSpec.describe Deck, type: :model do
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

    it "rejects private + password_users combination" do
      deck = build(:deck, visibility: "private", edit_permission: "password_users",
                          access_password: "secret123")
      expect(deck).not_to be_valid
      expect(deck.errors[:edit_permission]).to be_present
    end

    it "requires access_password when visibility is password_protected" do
      deck = build(:deck, visibility: "password_protected", access_password: nil)
      expect(deck).not_to be_valid
      expect(deck.errors[:access_password]).to be_present
    end

    it "requires access_password when edit_permission is password_users" do
      deck = build(:deck, edit_permission: "password_users", access_password: nil)
      expect(deck).not_to be_valid
      expect(deck.errors[:access_password]).to be_present
    end

    it "does not require access_password for private + owner_only" do
      deck = build(:deck, visibility: "private", edit_permission: "owner_only", access_password: nil)
      expect(deck).to be_valid
    end

    it "does not require access_password for everyone + owner_only" do
      deck = build(:deck, visibility: "everyone", edit_permission: "owner_only", access_password: nil)
      expect(deck).to be_valid
    end

    it "rejects access_password shorter than 8 characters" do
      deck = build(:deck, visibility: "password_protected", access_password: "short")
      expect(deck).not_to be_valid
      expect(deck.errors[:access_password]).to be_present
    end

    it "rejects access_password longer than 128 characters" do
      deck = build(:deck, visibility: "password_protected", access_password: "a" * 129)
      expect(deck).not_to be_valid
      expect(deck.errors[:access_password]).to be_present
    end

    it "is valid with access_password of exactly 8 characters" do
      deck = build(:deck, visibility: "password_protected", access_password: "a" * 8)
      expect(deck).to be_valid
    end
  end

  describe "visibility predicates" do
    it "defaults to everyone" do
      deck = Deck.new(name: "Test", user: build(:user))
      expect(deck.visibility).to eq("everyone")
    end

    it "#everyone? is true when visibility is everyone" do
      expect(build(:deck, visibility: "everyone").everyone?).to be true
    end

    it "#password_protected? is true when visibility is password_protected" do
      expect(build(:deck, visibility: "password_protected").password_protected?).to be true
    end

    it "#private? is true when visibility is private" do
      expect(build(:deck, visibility: "private").private?).to be true
    end

    it "#public? is an alias for #everyone?" do
      expect(build(:deck, visibility: "everyone").public?).to be true
    end
  end

  describe "#can_view?" do
    let(:owner) { build(:user, id: 1) }
    let(:other)  { build(:user, id: 2) }

    context "visibility: everyone" do
      let(:deck) { build(:deck, user: owner, visibility: "everyone") }

      it "allows everyone (nil user, no session)" do
        expect(deck.can_view?(nil, session_auth: false)).to be true
      end

      it "allows authenticated non-owner" do
        expect(deck.can_view?(other, session_auth: false)).to be true
      end

      it "allows owner" do
        expect(deck.can_view?(owner, session_auth: false)).to be true
      end
    end

    context "visibility: password_protected" do
      let(:deck) { build(:deck, user: owner, visibility: "password_protected") }

      it "denies unauthenticated user without session" do
        expect(deck.can_view?(nil, session_auth: false)).to be false
      end

      it "denies non-owner without session" do
        expect(deck.can_view?(other, session_auth: false)).to be false
      end

      it "allows non-owner with session" do
        expect(deck.can_view?(other, session_auth: true)).to be true
      end

      it "allows owner without session" do
        expect(deck.can_view?(owner, session_auth: false)).to be true
      end
    end

    context "visibility: private" do
      let(:deck) { build(:deck, user: owner, visibility: "private") }

      it "denies nil user" do
        expect(deck.can_view?(nil, session_auth: false)).to be false
      end

      it "denies non-owner" do
        expect(deck.can_view?(other, session_auth: false)).to be false
      end

      it "denies non-owner even with session" do
        expect(deck.can_view?(other, session_auth: true)).to be false
      end

      it "allows owner" do
        expect(deck.can_view?(owner, session_auth: false)).to be true
      end
    end
  end

  describe "#can_edit?" do
    let(:owner) { build(:user, id: 1) }
    let(:other)  { build(:user, id: 2) }

    context "edit_permission: owner_only" do
      let(:deck) { build(:deck, user: owner, edit_permission: "owner_only") }

      it "denies nil user" do
        expect(deck.can_edit?(nil, session_auth: false)).to be false
      end

      it "denies non-owner" do
        expect(deck.can_edit?(other, session_auth: false)).to be false
      end

      it "denies non-owner even with session" do
        expect(deck.can_edit?(other, session_auth: true)).to be false
      end

      it "allows owner" do
        expect(deck.can_edit?(owner, session_auth: false)).to be true
      end
    end

    context "edit_permission: password_users" do
      let(:deck) { build(:deck, user: owner, edit_permission: "password_users") }

      it "denies nil user" do
        expect(deck.can_edit?(nil, session_auth: true)).to be false
      end

      it "denies non-owner without session" do
        expect(deck.can_edit?(other, session_auth: false)).to be false
      end

      it "allows non-owner with session" do
        expect(deck.can_edit?(other, session_auth: true)).to be true
      end

      it "allows owner regardless of session" do
        expect(deck.can_edit?(owner, session_auth: false)).to be true
      end
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

  describe "#can_manage_cards?" do
    let(:owner) { build(:user, id: 1) }
    let(:deck)  { build(:deck, user: owner) }

    it "delegates to can_edit?" do
      expect(deck.can_manage_cards?(owner, session_auth: false)).to eq(deck.can_edit?(owner, session_auth: false))
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
