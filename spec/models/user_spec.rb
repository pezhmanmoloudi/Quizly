require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it "has many sessions with dependent destroy" do
      assoc = described_class.reflect_on_association(:sessions)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many decks with dependent destroy" do
      assoc = described_class.reflect_on_association(:decks)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many card_progresses with dependent destroy" do
      assoc = described_class.reflect_on_association(:card_progresses)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has one notification_preference with dependent destroy" do
      assoc = described_class.reflect_on_association(:notification_preference)
      expect(assoc.macro).to eq(:has_one)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end

  describe "notification_preference auto-creation" do
    it "creates a notification_preference after user creation" do
      user = create(:user)
      expect(user.notification_preference).to be_present
      expect(user.notification_preference.email_streaks_badges).to be(true)
      expect(user.notification_preference.email_study_reminders).to be(true)
      expect(user.notification_preference.reminder_time).to eq("08:00")
      expect(user.notification_preference.time_zone).to eq("UTC")
    end

    it "destroys notification_preference when user is destroyed" do
      user = create(:user)
      pref_id = user.notification_preference.id
      user.destroy
      expect(NotificationPreference.find_by(id: pref_id)).to be_nil
    end
  end

  describe "validations" do
    it "is invalid without an email address" do
      user = build(:user, email_address: "")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).not_to be_empty
    end

    it "is invalid with a duplicate email address (case-insensitive)" do
      create(:user, email_address: "test@example.com")
      duplicate = build(:user, email_address: "TEST@EXAMPLE.COM")
      expect(duplicate).not_to be_valid
    end

    it "is invalid with a malformed email" do
      user = build(:user, email_address: "not-an-email")
      expect(user).not_to be_valid
    end

    it "is invalid with a password shorter than 8 characters" do
      user = build(:user, password: "short", password_confirmation: "short")
      expect(user).not_to be_valid
    end

    it "normalizes email to lowercase and strips whitespace" do
      user = create(:user, email_address: "  Test@EXAMPLE.COM  ")
      expect(user.email_address).to eq("test@example.com")
    end
  end

  describe "#display_name" do
    it "returns the part of the email before @, capitalized" do
      user = build(:user, email_address: "pejman@example.com")
      expect(user.display_name).to eq("Pejman")
    end

    it "capitalizes a lowercase email prefix" do
      user = build(:user, email_address: "alice@example.com")
      expect(user.display_name).to eq("Alice")
    end

    it "handles an already-capitalized prefix" do
      user = build(:user, email_address: "Bob@example.com")
      expect(user.display_name).to eq("Bob")
    end
  end

  describe ".find_or_create_from_google" do
    def google_auth(uid: "uid-123", email: "person@example.com", name: "Person")
      OmniAuth::AuthHash.new(provider: "google_oauth2", uid: uid, info: { email: email, name: name })
    end

    it "creates a new persisted user when none matches" do
      user = nil
      expect { user = described_class.find_or_create_from_google(google_auth(uid: "brand-new")) }
        .to change(described_class, :count).by(1)
      expect(user).to be_persisted
      expect(user.google_uid).to eq("brand-new")
    end

    it "returns the existing user matched by google_uid" do
      existing = create(:user, google_uid: "known-uid")
      expect(described_class.find_or_create_from_google(google_auth(uid: "known-uid"))).to eq(existing)
    end

    it "links google_uid to an existing user matched by email" do
      existing = create(:user, email_address: "linkme@example.com", google_uid: nil)
      result = described_class.find_or_create_from_google(google_auth(uid: "linked-uid", email: "linkme@example.com"))
      expect(result).to eq(existing)
      expect(existing.reload.google_uid).to eq("linked-uid")
    end
  end
end
