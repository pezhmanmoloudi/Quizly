require "rails_helper"

RSpec.describe Follows::DeckPublishedNotificationJob, type: :job do
  let(:deck_owner) { create(:user) }
  let(:follower)   { create(:user) }

  def public_deck_for(user)
    deck = create(:deck, user: user)
    create(:flashcard, deck: deck)
    deck.reload
    deck.update_columns(visibility: "public")
    deck
  end

  describe "#perform" do
    context "when the deck exists and is public" do
      let(:deck) { public_deck_for(deck_owner) }

      before do
        create(:follow, follower: follower, followed: deck_owner)
        follower.notification_preference.update!(in_app_following_activity: true)
      end

      it "creates a notification for the follower" do
        expect {
          described_class.new.perform(deck.id)
        }.to change(Notification, :count).by(1)
      end

      it "creates a notification with the correct attributes" do
        described_class.new.perform(deck.id)
        notification = Notification.last
        expect(notification.recipient).to eq(follower)
        expect(notification.actor).to eq(deck_owner)
        expect(notification.event_type).to eq("followed_user_published_deck")
        expect(notification.notifiable).to eq(deck)
      end

      it "skips followers whose in_app_following_activity preference is false" do
        follower.notification_preference.update!(in_app_following_activity: false)
        expect {
          described_class.new.perform(deck.id)
        }.not_to change(Notification, :count)
      end
    end

    context "when the deck no longer exists" do
      it "returns without raising and creates no notifications" do
        expect {
          described_class.new.perform(0)
        }.not_to change(Notification, :count)
      end
    end

    context "when the deck is no longer public" do
      it "returns without creating notifications" do
        deck = create(:deck, user: deck_owner)
        create(:flashcard, deck: deck)
        deck.reload
        create(:follow, follower: follower, followed: deck_owner)

        expect {
          described_class.new.perform(deck.id)
        }.not_to change(Notification, :count)
      end
    end

    context "when the deck owner has more followers than MAX_FOLLOWERS" do
      it "skips fan-out and creates no notifications" do
        deck = public_deck_for(deck_owner)
        create(:follow, follower: follower, followed: deck_owner)
        follower.notification_preference.update!(in_app_following_activity: true)

        stub_const("Follows::DeckPublishedNotificationJob::MAX_FOLLOWERS", 0)

        expect {
          described_class.new.perform(deck.id)
        }.not_to change(Notification, :count)
      end
    end

    context "with multiple followers having mixed preferences" do
      it "only notifies followers who have opted in" do
        deck = public_deck_for(deck_owner)
        opted_in     = create(:user)
        opted_out    = create(:user)

        create(:follow, follower: opted_in,  followed: deck_owner)
        create(:follow, follower: opted_out, followed: deck_owner)

        opted_in.notification_preference.update!(in_app_following_activity: true)
        opted_out.notification_preference.update!(in_app_following_activity: false)

        expect {
          described_class.new.perform(deck.id)
        }.to change(Notification, :count).by(1)

        expect(Notification.last.recipient).to eq(opted_in)
      end
    end
  end
end
