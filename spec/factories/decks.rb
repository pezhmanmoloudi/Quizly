FactoryBot.define do
  factory :deck do
    association :user
    sequence(:title) { |n| "Deck #{n}" }
    description { "A test deck" }
  end
end
