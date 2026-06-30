FactoryBot.define do
  factory :deck_folder_tag do
    association :folder_tag
    association :deck
  end
end
