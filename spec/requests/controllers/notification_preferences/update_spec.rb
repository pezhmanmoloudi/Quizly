require "rails_helper"

RSpec.describe "NotificationPreferences#update", type: :request do
  let(:user) { create(:user) }

  describe "PATCH /notification_preferences" do
    context "when authenticated" do
      before { sign_in(user) }

      it "turns off email_streaks_badges" do
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "0",
            email_study_reminders: "1",
            reminder_time: "08:00",
            time_zone: "UTC"
          }
        }
        expect(user.reload.notification_preference.email_streaks_badges).to be(false)
        expect(response).to redirect_to(notification_preferences_path)
      end

      it "turns off email_study_reminders" do
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "1",
            email_study_reminders: "0",
            reminder_time: "08:00",
            time_zone: "UTC"
          }
        }
        expect(user.reload.notification_preference.email_study_reminders).to be(false)
        expect(response).to redirect_to(notification_preferences_path)
      end

      it "updates reminder_time" do
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "1",
            email_study_reminders: "1",
            reminder_time: "14:00",
            time_zone: "UTC"
          }
        }
        expect(user.reload.notification_preference.reminder_time).to eq("14:00")
      end

      it "updates time_zone" do
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "1",
            email_study_reminders: "1",
            reminder_time: "08:00",
            time_zone: "London"
          }
        }
        expect(user.reload.notification_preference.time_zone).to eq("London")
      end

      it "sets flash notice on success" do
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "1",
            email_study_reminders: "1",
            reminder_time: "08:00",
            time_zone: "UTC"
          }
        }
        expect(flash[:notice]).to eq(I18n.t("accounts.updated.notifications"))
      end

      it "rejects invalid reminder_time" do
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "1",
            email_study_reminders: "1",
            reminder_time: "bad",
            time_zone: "UTC"
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects invalid time_zone" do
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "1",
            email_study_reminders: "1",
            reminder_time: "08:00",
            time_zone: "Fake/Zone"
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not change preferences on validation failure" do
        original_time = user.notification_preference.reminder_time
        patch notification_preferences_path, params: {
          notification_preference: {
            email_streaks_badges: "1",
            email_study_reminders: "1",
            reminder_time: "bad",
            time_zone: "UTC"
          }
        }
        expect(user.reload.notification_preference.reminder_time).to eq(original_time)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch notification_preferences_path, params: {
          notification_preference: { email_streaks_badges: "0" }
        }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
