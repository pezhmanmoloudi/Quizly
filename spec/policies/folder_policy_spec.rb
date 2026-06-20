require "rails_helper"

RSpec.describe FolderPolicy, type: :policy do
  let(:owner)  { create(:user) }
  let(:other)  { create(:user) }
  let(:folder) { create(:folder, user: owner) }

  shared_examples "owner-only action" do |action|
    it "permits the owner" do
      expect(described_class.new(owner, folder).public_send(:"#{action}?")).to be true
    end

    it "denies another user" do
      expect(described_class.new(other, folder).public_send(:"#{action}?")).to be false
    end

    it "denies a nil user" do
      expect(described_class.new(nil, folder).public_send(:"#{action}?")).to be false
    end
  end

  describe "#create?" do
    it "permits any authenticated user" do
      expect(described_class.new(other, folder).create?).to be true
    end

    it "denies a nil (guest) user" do
      expect(described_class.new(nil, folder).create?).to be false
    end
  end

  describe "#update?"      do include_examples "owner-only action", :update      end
  describe "#destroy?"     do include_examples "owner-only action", :destroy     end
  describe "#add_deck?"    do include_examples "owner-only action", :add_deck    end
  describe "#remove_deck?" do include_examples "owner-only action", :remove_deck end
end
