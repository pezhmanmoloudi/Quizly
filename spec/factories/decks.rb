FactoryBot.define do
  factory :deck do
    association :user
    sequence(:name) { |n| "Deck #{n}" }
    description { "A test deck" }
    visibility { "private" }
    edit_permission { "owner_only" }

    trait :everyone do
      visibility { "everyone" }
    end

    trait :public do
      visibility { "everyone" }
    end

    trait :password_protected do
      visibility { "password_protected" }
      access_password { "secret123" }
    end

    trait :private do
      visibility { "private" }
    end

    trait :editable_by_password do
      visibility { "everyone" }
      edit_permission { "password_users" }
      access_password { "secret123" }
    end
  end
end
