FactoryBot.define do
  factory :learn_session do
    association :user
    association :deck
    cards_total    { 3 }
    cards_mastered { 0 }
    started_at     { Time.current }
    finished_at    { nil }

    trait :completed do
      cards_mastered { 3 }
      finished_at    { Time.current }
    end
  end
end
