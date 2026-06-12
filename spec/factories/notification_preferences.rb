FactoryBot.define do
  factory :notification_preference do
    association :user
    email_streaks_badges  { true }
    email_study_reminders { true }
    reminder_time         { "08:00" }
    time_zone             { "UTC" }
  end
end
