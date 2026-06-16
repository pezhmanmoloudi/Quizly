require "rails_helper"

RSpec.describe FlashcardPolicy, type: :policy do
  let(:owner)     { create(:user) }
  let(:other)     { create(:user) }
  let(:deck)      { create(:deck, user: owner) }
  let(:flashcard) { create(:flashcard, deck: deck) }

  shared_examples "owner-only action" do |action|
    it "permits the deck owner" do
      expect(described_class.new(owner, flashcard).public_send(:"#{action}?")).to be true
    end

    it "denies another user" do
      expect(described_class.new(other, flashcard).public_send(:"#{action}?")).to be false
    end

    it "denies nil user" do
      expect(described_class.new(nil, flashcard).public_send(:"#{action}?")).to be false
    end
  end

  describe "#create?" do
    include_examples "owner-only action", :create
  end

  describe "#update?" do
    include_examples "owner-only action", :update
  end

  describe "#destroy?" do
    include_examples "owner-only action", :destroy
  end

  describe "#restore?" do
    let(:flashcard) do
      fc = create(:flashcard, deck: deck)
      fc.update_column(:deleted_at, Time.current)
      fc
    end

    include_examples "owner-only action", :restore
  end
end
