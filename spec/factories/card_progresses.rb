FactoryBot.define do
  factory :card_progress do
    association :user
    association :flashcard
    ease_factor   { 2.5 }
    interval      { 1 }
    repetitions   { 0 }
    next_review_at  { Time.current }
    last_reviewed_at { nil }

    trait :due do
      next_review_at { 1.day.ago }
    end

    trait :future do
      next_review_at { 1.day.from_now }
    end

    trait :reviewed do
      repetitions    { 2 }
      interval       { 6 }
      next_review_at { 1.day.ago }
      last_reviewed_at { 1.day.ago }
    end
  end
end
