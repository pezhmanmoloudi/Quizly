require "rails_helper"

RSpec.describe NotificationPolicy, type: :policy do
  let(:recipient) { create(:user) }
  let(:other)     { create(:user) }

  describe "#index?" do
    it "permits any authenticated user" do
      expect(described_class.new(recipient, Notification).index?).to be true
    end
  end

  describe "#mark_read?" do
    let(:notification) { create(:notification, recipient: recipient) }

    it "permits the recipient" do
      expect(described_class.new(recipient, notification).mark_read?).to be true
    end

    it "denies another user" do
      expect(described_class.new(other, notification).mark_read?).to be false
    end
  end

  describe "#mark_all_read?" do
    it "permits any authenticated user" do
      expect(described_class.new(recipient, Notification).mark_all_read?).to be true
    end
  end

  describe "Scope" do
    let!(:own_notification)   { create(:notification, recipient: recipient) }
    let!(:other_notification) { create(:notification, recipient: other) }

    subject(:scope) { described_class::Scope.new(recipient, Notification.all).resolve }

    it "includes own notifications" do
      expect(scope).to include(own_notification)
    end

    it "excludes other users' notifications" do
      expect(scope).not_to include(other_notification)
    end
  end
end
