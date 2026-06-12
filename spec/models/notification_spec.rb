require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "associations" do
    it "belongs_to recipient" do
      assoc = described_class.reflect_on_association(:recipient)
      expect(assoc.macro).to eq(:belongs_to)
      expect(assoc.options[:class_name]).to eq("User")
    end

    it "belongs_to actor (optional)" do
      assoc = described_class.reflect_on_association(:actor)
      expect(assoc.macro).to eq(:belongs_to)
      expect(assoc.options[:optional]).to be true
    end

    it "belongs_to notifiable polymorphically (optional)" do
      assoc = described_class.reflect_on_association(:notifiable)
      expect(assoc.macro).to eq(:belongs_to)
      expect(assoc.options[:polymorphic]).to be true
      expect(assoc.options[:optional]).to be true
    end
  end

  describe "validations" do
    it "is valid with a known event_type" do
      notification = build(:notification, event_type: "badge_earned")
      expect(notification).to be_valid
    end

    it "is invalid with an unknown event_type" do
      notification = build(:notification, event_type: "unknown_event")
      expect(notification).not_to be_valid
      expect(notification.errors[:event_type]).to be_present
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }

    before do
      create(:notification, recipient: user, read: false)
      create(:notification, recipient: user, read: false)
      create(:notification, :read, recipient: user)
    end

    describe ".unread" do
      it "returns only unread notifications" do
        expect(user.notifications.unread.count).to eq(2)
      end
    end

    describe ".recent" do
      it "returns at most 20 notifications in descending order" do
        25.times { create(:notification, recipient: user) }
        results = user.notifications.recent
        expect(results.size).to eq(20)
        expect(results.first.created_at).to be >= results.last.created_at
      end
    end
  end

  describe "#mark_read!" do
    it "sets read to true and records read_at" do
      notification = create(:notification, read: false)
      expect { notification.mark_read! }.to change { notification.read }.from(false).to(true)
      expect(notification.read_at).to be_present
    end

    it "is idempotent — does not update if already read" do
      read_at = 1.hour.ago
      notification = create(:notification, :read, read_at: read_at)
      expect { notification.mark_read! }.not_to change { notification.reload.read_at }
    end
  end
end
