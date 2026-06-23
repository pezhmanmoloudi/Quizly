FactoryBot.define do
  factory :deck do
    association :user
    sequence(:name) { |n| "Deck #{n}" }
    description { "A test deck" }
    visibility { "private" }
    access_mode { "open" }
    term_language       { "en" }
    definition_language { "en" }

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

    trait :password_protected do
      visibility { "public" }
      access_mode { "password" }
      password { "secret123" }
      after(:create) { |deck| create(:flashcard, deck: deck) }
    end

    trait :unlisted_password_protected do
      visibility { "unlisted" }
      access_mode { "password" }
      password { "secret123" }
      after(:create) { |deck| create(:flashcard, deck: deck) }
    end
  end
end
