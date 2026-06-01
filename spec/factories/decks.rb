FactoryBot.define do
  factory :deck do
    association :user
    sequence(:name) { |n| "Deck #{n}" }
    description { "A test deck" }
  end
end
