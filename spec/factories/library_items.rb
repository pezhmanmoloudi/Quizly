FactoryBot.define do
  factory :library_item do
    association :user
    association :deck
  end
end
