require "rails_helper"

RSpec.describe DeckPolicy, type: :policy do
  subject(:policy) { described_class.new(user, deck) }

  let(:owner) { create(:user) }
  let(:other)  { create(:user) }

  shared_examples "owner-only action" do |action|
    it "permits the owner" do
      expect(described_class.new(owner, deck).public_send(:"#{action}?")).to be true
    end

    it "denies another user" do
      expect(described_class.new(other, deck).public_send(:"#{action}?")).to be false
    end

    it "denies a nil user" do
      expect(described_class.new(nil, deck).public_send(:"#{action}?")).to be false
    end
  end

  describe "#show?" do
    context "public deck" do
      let(:deck) { create(:deck, :public, user: owner) }

      it "permits owner" do
        expect(described_class.new(owner, deck).show?).to be true
      end

      it "permits another user" do
        expect(described_class.new(other, deck).show?).to be true
      end

      it "permits nil user (guest)" do
        expect(described_class.new(nil, deck).show?).to be true
      end
    end

    context "unlisted deck" do
      let(:deck) { create(:deck, :unlisted, user: owner) }

      it "permits owner" do
        expect(described_class.new(owner, deck).show?).to be true
      end

      it "permits another user (link sharing)" do
        expect(described_class.new(other, deck).show?).to be true
      end

      it "permits nil user (guest with link)" do
        expect(described_class.new(nil, deck).show?).to be true
      end
    end

    context "private deck" do
      let(:deck) { create(:deck, :private, user: owner) }

      it "permits owner" do
        expect(described_class.new(owner, deck).show?).to be true
      end

      it "denies another user" do
        expect(described_class.new(other, deck).show?).to be false
      end

      it "denies nil user" do
        expect(described_class.new(nil, deck).show?).to be false
      end
    end
  end

  describe "#update?" do
    let(:deck) { create(:deck, :public, user: owner) }
    include_examples "owner-only action", :update
  end

  describe "#destroy?" do
    let(:deck) { create(:deck, :public, user: owner) }
    include_examples "owner-only action", :destroy
  end

  describe "#manage_access?" do
    let(:deck) { create(:deck, :public, user: owner) }
    include_examples "owner-only action", :manage_access
  end

  describe "#manage_flashcards?" do
    let(:deck) { create(:deck, :public, user: owner) }
    include_examples "owner-only action", :manage_flashcards
  end

  describe "#export?" do
    let(:deck) { create(:deck, :public, user: owner) }
    include_examples "owner-only action", :export
  end

  describe "#learn?" do
    context "public deck" do
      let(:deck) { create(:deck, :public, user: owner) }

      it "permits the owner" do
        expect(described_class.new(owner, deck).learn?).to be true
      end

      it "permits another authenticated user" do
        expect(described_class.new(other, deck).learn?).to be true
      end

      it "denies a nil (guest) user — learn requires a session" do
        expect(described_class.new(nil, deck).learn?).to be false
      end
    end

    context "private deck" do
      let(:deck) { create(:deck, :private, user: owner) }

      it "permits owner" do
        expect(described_class.new(owner, deck).learn?).to be true
      end

      it "denies another user" do
        expect(described_class.new(other, deck).learn?).to be false
      end
    end
  end

  describe "#test?" do
    context "public deck" do
      let(:deck) { create(:deck, :public, user: owner) }

      it "permits the owner" do
        expect(described_class.new(owner, deck).test?).to be true
      end

      it "permits another authenticated user" do
        expect(described_class.new(other, deck).test?).to be true
      end

      it "denies a nil (guest) user — test requires a session" do
        expect(described_class.new(nil, deck).test?).to be false
      end
    end

    context "private deck" do
      let(:deck) { create(:deck, :private, user: owner) }

      it "permits owner" do
        expect(described_class.new(owner, deck).test?).to be true
      end

      it "denies another user" do
        expect(described_class.new(other, deck).test?).to be false
      end
    end
  end

  describe "#copy?" do
    context "public deck" do
      let(:deck) { create(:deck, :public, user: owner) }

      it "permits another authenticated user" do
        expect(described_class.new(other, deck).copy?).to be true
      end

      it "denies the owner" do
        expect(described_class.new(owner, deck).copy?).to be false
      end

      it "denies nil user" do
        expect(described_class.new(nil, deck).copy?).to be false
      end
    end

    context "unlisted deck" do
      let(:deck) { create(:deck, :unlisted, user: owner) }

      it "permits another authenticated user" do
        expect(described_class.new(other, deck).copy?).to be true
      end
    end

    context "private deck" do
      let(:deck) { create(:deck, :private, user: owner) }

      it "denies another authenticated user" do
        expect(described_class.new(other, deck).copy?).to be false
      end
    end
  end

  describe "#save?" do
    context "public deck" do
      let(:deck) { create(:deck, :public, user: owner) }

      it "permits another authenticated user" do
        expect(described_class.new(other, deck).save?).to be true
      end

      it "permits the owner" do
        expect(described_class.new(owner, deck).save?).to be true
      end

      it "denies nil user (guest)" do
        expect(described_class.new(nil, deck).save?).to be false
      end
    end

    context "private deck" do
      let(:deck) { create(:deck, :private, user: owner) }

      it "permits another authenticated user" do
        expect(described_class.new(other, deck).save?).to be true
      end
    end
  end

  describe "Scope" do
    let!(:public_deck)   { create(:deck, :public,   user: owner) }
    let!(:unlisted_deck) { create(:deck, :unlisted, user: owner) }
    let!(:private_deck)  { create(:deck, :private,  user: owner) }
    let!(:other_private) { create(:deck, :private,  user: other) }

    subject(:scope) { described_class::Scope.new(user, Deck.all).resolve }

    context "as the owner" do
      let(:user) { owner }

      it "includes own private deck" do
        expect(scope).to include(private_deck)
      end

      it "includes own public and unlisted decks" do
        expect(scope).to include(public_deck, unlisted_deck)
      end

      it "excludes other user's private deck" do
        expect(scope).not_to include(other_private)
      end
    end

    context "as another authenticated user" do
      let(:user) { other }

      it "includes public and unlisted decks from owner" do
        expect(scope).to include(public_deck, unlisted_deck)
      end

      it "excludes owner's private deck" do
        expect(scope).not_to include(private_deck)
      end

      it "includes own private deck" do
        expect(scope).to include(other_private)
      end
    end

    context "as a nil (guest) user" do
      let(:user) { nil }

      it "includes public and unlisted decks" do
        expect(scope).to include(public_deck, unlisted_deck)
      end

      it "excludes any private deck" do
        expect(scope).not_to include(private_deck, other_private)
      end
    end
  end
end
