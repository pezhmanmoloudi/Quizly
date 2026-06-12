require "rails_helper"

RSpec.describe NotificationPreference, type: :model do
  describe "associations" do
    it "belongs to user" do
      assoc = described_class.reflect_on_association(:user)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    subject { build(:notification_preference) }

    describe "reminder_time" do
      it "is valid with HH:MM format" do
        subject.reminder_time = "08:00"
        expect(subject).to be_valid
      end

      it "is valid at boundary 00:00" do
        subject.reminder_time = "00:00"
        expect(subject).to be_valid
      end

      it "is valid at boundary 23:59" do
        subject.reminder_time = "23:59"
        expect(subject).to be_valid
      end

      it "is invalid with single-digit hour" do
        subject.reminder_time = "8:00"
        expect(subject).not_to be_valid
        expect(subject.errors[:reminder_time]).not_to be_empty
      end

      it "is invalid with hour 24" do
        subject.reminder_time = "24:00"
        expect(subject).not_to be_valid
      end

      it "is invalid with arbitrary string" do
        subject.reminder_time = "morning"
        expect(subject).not_to be_valid
      end
    end

    describe "time_zone" do
      it "is valid with a known ActiveSupport::TimeZone name" do
        subject.time_zone = "UTC"
        expect(subject).to be_valid
      end

      it "is valid with a named zone like London" do
        subject.time_zone = "London"
        expect(subject).to be_valid
      end

      it "is invalid with an unknown zone" do
        subject.time_zone = "Mars/Olympus"
        expect(subject).not_to be_valid
        expect(subject.errors[:time_zone]).not_to be_empty
      end

      it "is invalid with blank" do
        subject.time_zone = ""
        expect(subject).not_to be_valid
      end
    end
  end
end
