FactoryBot.define do
  factory :notification do
    association :recipient, factory: :user
    event_type { "badge_earned" }
    read       { false }

    trait :read do
      read    { true }
      read_at { 1.hour.ago }
    end

    trait :with_actor do
      association :actor, factory: :user
    end
  end
end
