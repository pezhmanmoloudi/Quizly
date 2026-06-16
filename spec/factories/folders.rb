FactoryBot.define do
  factory :folder do
    association :user
    sequence(:name) { |n| "Folder #{n}" }
    description { "A test folder" }
  end
end
