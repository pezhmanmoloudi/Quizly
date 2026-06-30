FactoryBot.define do
  factory :folder_tag do
    association :folder
    sequence(:name) { |n| "Tag #{n}" }
  end
end
