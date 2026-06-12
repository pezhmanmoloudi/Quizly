require "rails_helper"

RSpec.describe CreateNotification, type: :service do
  let(:recipient) { create(:user) }
  let(:actor)     { create(:user) }

  describe ".call" do
    it "creates a notification and returns it" do
      notification = described_class.call(recipient: recipient, event_type: "badge_earned")
      expect(notification).to be_a(Notification)
      expect(notification).to be_persisted
      expect(notification.recipient).to eq(recipient)
      expect(notification.event_type).to eq("badge_earned")
    end

    it "increments the notification count" do
      expect {
        described_class.call(recipient: recipient, event_type: "badge_earned")
      }.to change(Notification, :count).by(1)
    end

    it "sets actor and notifiable when provided" do
      user_badge = create(:user_badge, user: recipient)
      notification = described_class.call(
        recipient:  recipient,
        event_type: "badge_earned",
        actor:      actor,
        notifiable: user_badge
      )
      expect(notification.actor).to eq(actor)
      expect(notification.notifiable).to eq(user_badge)
    end

    it "creates with actor nil by default" do
      notification = described_class.call(recipient: recipient, event_type: "badge_earned")
      expect(notification.actor).to be_nil
    end

    it "returns nil and creates no record for an unknown event_type" do
      expect {
        result = described_class.call(recipient: recipient, event_type: "nonexistent")
        expect(result).to be_nil
      }.not_to change(Notification, :count)
    end
  end
end
