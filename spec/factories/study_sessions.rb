FactoryBot.define do
  factory :study_session do
    association :user
    association :deck
    cards_reviewed { 5 }
    cards_correct  { 4 }
    started_at     { Time.current }
    finished_at    { nil }

    trait :completed do
      finished_at { Time.current }
    end
  end
end
