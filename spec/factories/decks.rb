FactoryBot.define do
  factory :deck do
    association :user
    sequence(:name) { |n| "Deck #{n}" }
    description { "A test deck" }
    visibility { "private" }
    edit_permission { "only_me" }

    trait :public do
      visibility { "public" }
      after(:create) { |deck| create(:flashcard, deck: deck) }
    end

    trait :unlisted do
      visibility { "unlisted" }
      after(:create) { |deck| create(:flashcard, deck: deck) }
    end

    trait :private do
      visibility { "private" }
    end

    trait :editable_by_password do
      visibility { "public" }
      edit_permission { "people_with_password" }
      password { "secret123" }
      after(:create) { |deck| create(:flashcard, deck: deck) }
    end
  end
end
