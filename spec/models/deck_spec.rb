require "rails_helper"

RSpec.describe Deck, type: :model do
  describe "scopes" do
    def public_deck_with_flashcard
      d = create(:deck)
      create(:flashcard, deck: d)
      d.reload.update!(visibility: "public")
      d
    end

    def unlisted_deck_with_flashcard
      d = create(:deck)
      create(:flashcard, deck: d)
      d.reload.update!(visibility: "unlisted")
      d
    end

    it ".discoverable includes complete public decks" do
      deck = public_deck_with_flashcard
      expect(Deck.discoverable).to include(deck)
    end

    it ".discoverable excludes public decks with no flashcards" do
      deck = public_deck_with_flashcard
      deck.flashcards.destroy_all
      deck.reload
      expect(Deck.discoverable).not_to include(deck)
    end

    it ".discoverable excludes private decks" do
      create(:deck, :private)
      public_deck_with_flashcard
      expect(Deck.discoverable.map(&:visibility)).not_to include("private")
    end

    it ".discoverable excludes unlisted decks" do
      unlisted_deck_with_flashcard
      public_deck_with_flashcard
      expect(Deck.discoverable.map(&:visibility)).not_to include("unlisted")
    end

    it ".discoverable excludes both unlisted and private decks" do
      unlisted_deck_with_flashcard
      create(:deck, :private)
      public_deck_with_flashcard
      result = Deck.discoverable.map(&:visibility)
      expect(result).not_to include("unlisted")
      expect(result).not_to include("private")
    end

    it ".complete includes decks with at least one flashcard" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      expect(Deck.complete).to include(deck)
    end

    it ".complete excludes decks with no flashcards" do
      deck = create(:deck)
      expect(Deck.complete).not_to include(deck)
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

    it "has many deck_folders" do
      assoc = described_class.reflect_on_association(:deck_folders)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many folders through deck_folders" do
      assoc = described_class.reflect_on_association(:folders)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:through]).to eq(:deck_folders)
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

    it "rejects an unsupported access_mode value" do
      deck = build(:deck, access_mode: "admin_only")
      expect(deck).not_to be_valid
    end

    it "rejects private + password access_mode combination" do
      deck = build(:deck, visibility: "private", access_mode: "password", password: "secret123")
      expect(deck).not_to be_valid
      expect(deck.errors[:access_mode]).to be_present
    end

    it "allows unlisted + password access_mode combination" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      deck.reload
      deck.visibility = "unlisted"
      deck.access_mode = "password"
      deck.password = "secret123"
      expect(deck).to be_valid
    end

    it "is valid with unlisted + open access_mode" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      deck.reload
      deck.visibility = "unlisted"
      expect(deck).to be_valid
    end

    it "requires password when access_mode is password" do
      deck = build(:deck, access_mode: "password", password: nil)
      expect(deck).not_to be_valid
      expect(deck.errors[:password]).to be_present
    end

    it "does not require password for private + open access_mode" do
      deck = build(:deck, visibility: "private", access_mode: "open", password: nil)
      expect(deck).to be_valid
    end

    it "does not require password for public + open access_mode" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      deck.reload
      deck.visibility = "public"
      deck.access_mode = "open"
      expect(deck).to be_valid
    end

    it "rejects password shorter than 8 characters" do
      deck = build(:deck, access_mode: "password", password: "short")
      expect(deck).not_to be_valid
      expect(deck.errors[:password]).to be_present
    end

    it "rejects password longer than 128 characters" do
      deck = build(:deck, access_mode: "password", password: "a" * 129)
      expect(deck).not_to be_valid
      expect(deck.errors[:password]).to be_present
    end

    it "is valid with password of exactly 8 characters" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      deck.reload
      deck.visibility = "public"
      deck.access_mode = "password"
      deck.password = "a" * 8
      expect(deck).to be_valid
    end
  end

  describe "visibility predicates" do
    it "defaults to private" do
      deck = Deck.new(name: "Test", user: build(:user))
      expect(deck.visibility).to eq("private")
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

  describe "access_mode predicates" do
    it "defaults to open" do
      deck = Deck.new(name: "Test", user: build(:user))
      expect(deck.access_mode).to eq("open")
    end

    it "#open? is true when access_mode is open" do
      expect(build(:deck, access_mode: "open").open?).to be true
    end

    it "#password_protected? is true when access_mode is password" do
      expect(build(:deck, access_mode: "password").password_protected?).to be true
    end

    it "#password_protected? is false when access_mode is open" do
      expect(build(:deck, access_mode: "open").password_protected?).to be false
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

  describe "#complete? / #draft?" do
    it "is complete when it has a name and at least one flashcard" do
      deck = create(:deck, name: "My Deck")
      create(:flashcard, deck: deck)
      deck.reload
      expect(deck.complete?).to be true
      expect(deck.draft?).to be false
    end

    it "is a draft when it has no flashcards" do
      deck = create(:deck, name: "My Deck")
      expect(deck.complete?).to be false
      expect(deck.draft?).to be true
    end
  end

  describe "#completeness_for_sharing" do
    it "blocks changing a private deck to public when it has no flashcards" do
      deck = create(:deck, visibility: "private")
      deck.visibility = "public"
      expect(deck).not_to be_valid
      expect(deck.errors[:base]).to be_present
    end

    it "blocks changing a private deck to unlisted when it has no flashcards" do
      deck = create(:deck, visibility: "private")
      deck.visibility = "unlisted"
      expect(deck).not_to be_valid
      expect(deck.errors[:base]).to be_present
    end

    it "allows changing to public when the deck has at least one flashcard" do
      deck = create(:deck, visibility: "private")
      create(:flashcard, deck: deck)
      deck.reload
      deck.visibility = "public"
      expect(deck).to be_valid
    end

    it "does not block private decks with no flashcards" do
      deck = create(:deck, visibility: "private")
      expect(deck).to be_valid
    end

    it "is invalid when a public deck has no flashcards, even without a visibility change" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      deck.reload.update!(visibility: "public")
      deck.flashcards.destroy_all
      deck.reload
      expect(deck).not_to be_valid
      expect(deck.errors[:base]).to be_present
    end
  end

  describe "#just_published? / publish notification callback" do
    let(:deck_owner) { create(:user) }

    def deck_with_flashcard(visibility: "private")
      d = create(:deck, user: deck_owner, visibility: "private")
      create(:flashcard, deck: d)
      d.reload
      d.update_columns(visibility: visibility)
      d
    end

    it "enqueues DeckPublishedNotificationJob when visibility changes from private to public" do
      deck = deck_with_flashcard(visibility: "private")
      expect {
        deck.update!(visibility: "public")
      }.to have_enqueued_job(Follows::DeckPublishedNotificationJob).with(deck.id)
    end

    it "enqueues DeckPublishedNotificationJob when visibility changes from unlisted to public" do
      deck = deck_with_flashcard(visibility: "unlisted")
      expect {
        deck.update!(visibility: "public")
      }.to have_enqueued_job(Follows::DeckPublishedNotificationJob).with(deck.id)
    end

    it "does not enqueue the job when an already-public deck is saved with other changes" do
      deck = deck_with_flashcard(visibility: "public")
      expect {
        deck.update!(name: "Updated Name")
      }.not_to have_enqueued_job(Follows::DeckPublishedNotificationJob)
    end

    it "does not enqueue the job when visibility changes from public to private" do
      deck = deck_with_flashcard(visibility: "public")
      expect {
        deck.update_columns(visibility: "private")
        deck.reload
        deck.update!(name: "Trigger save without visibility change")
      }.not_to have_enqueued_job(Follows::DeckPublishedNotificationJob)
    end

    it "does not enqueue the job when visibility changes from public to unlisted" do
      deck = deck_with_flashcard(visibility: "public")
      expect {
        deck.update_columns(visibility: "unlisted")
        deck.reload
        deck.update!(name: "Trigger save")
      }.not_to have_enqueued_job(Follows::DeckPublishedNotificationJob)
    end
  end

  describe "term_language / definition_language validations" do
    it "is valid with a recognised term_language code" do
      deck = build(:deck, term_language: "en")
      expect(deck).to be_valid
    end

    it "is valid with a recognised definition_language code" do
      deck = build(:deck, definition_language: "fa")
      expect(deck).to be_valid
    end

    it "is valid with blank term_language" do
      deck = build(:deck, term_language: nil)
      expect(deck).to be_valid
    end

    it "is valid with blank definition_language" do
      deck = build(:deck, definition_language: nil)
      expect(deck).to be_valid
    end

    it "is invalid with an unrecognised term_language code" do
      deck = build(:deck, term_language: "xx_unknown")
      expect(deck).not_to be_valid
      expect(deck.errors[:term_language]).to be_present
    end

    it "is invalid with an unrecognised definition_language code" do
      deck = build(:deck, definition_language: "xx_unknown")
      expect(deck).not_to be_valid
      expect(deck.errors[:definition_language]).to be_present
    end
  end

  describe "#sync_flashcard_languages" do
    it "updates front_language on all flashcards when term_language changes" do
      deck = create(:deck, term_language: "en", definition_language: "fa")
      card = create(:flashcard, deck: deck, front_language: "en", back_language: "fa")
      deck.update!(term_language: "de")
      expect(card.reload.front_language).to eq("de")
    end

    it "updates back_language on all flashcards when definition_language changes" do
      deck = create(:deck, term_language: "en", definition_language: "fa")
      card = create(:flashcard, deck: deck, front_language: "en", back_language: "fa")
      deck.update!(definition_language: "ar")
      expect(card.reload.back_language).to eq("ar")
    end

    it "does NOT trigger sync when neither language column changes" do
      deck  = create(:deck, term_language: "en", definition_language: "fa")
      card  = create(:flashcard, deck: deck, front_language: "en", back_language: "fa")
      deck.update!(name: "New Name")
      expect(card.reload.front_language).to eq("en")
    end

    it "excludes soft-deleted flashcards (already excluded by default_scope)" do
      deck = create(:deck, term_language: "en", definition_language: "fa")
      card = create(:flashcard, deck: deck, front_language: "en", back_language: "fa")
      card.soft_delete!
      deck.update!(term_language: "de")
      expect(Flashcard.unscoped.find(card.id).front_language).to eq("en")
    end
  end

  describe "dependent destruction" do
    it "destroys associated flashcards when the deck is deleted" do
      deck = create(:deck)
      create(:flashcard, deck: deck)
      expect { deck.destroy }.to change(Flashcard, :count).by(-1)
    end

    it "destroys a deck that has soft-deleted flashcards without a FK error" do
      deck = create(:deck)
      card = create(:flashcard, deck: deck)
      card.soft_delete!
      expect { deck.destroy }.not_to raise_error
      expect(Deck.exists?(deck.id)).to be false
      expect(Flashcard.unscoped.where(deck_id: deck.id).count).to eq(0)
    end

    it "destroys a deck whose soft-deleted flashcards still have learn_session_items" do
      deck    = create(:deck)
      card    = create(:flashcard, deck: deck)
      session = create(:learn_session, deck: deck, user: deck.user)
      create(:learn_session_item, learn_session: session, flashcard: card)
      card.soft_delete!

      expect { deck.destroy }.not_to raise_error
      expect(Deck.exists?(deck.id)).to be false
      expect(Flashcard.unscoped.where(deck_id: deck.id).count).to eq(0)
      expect(LearnSessionItem.where(flashcard_id: card.id).count).to eq(0)
    end
  end
end
