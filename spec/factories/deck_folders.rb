FactoryBot.define do
  factory :deck_folder do
    association :deck
    association :folder
  end
end
