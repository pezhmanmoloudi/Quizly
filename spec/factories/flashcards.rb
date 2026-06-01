FactoryBot.define do
  factory :flashcard do
    association :deck
    sequence(:front_content) { |n| "Question #{n}" }
    sequence(:back_content)  { |n| "Answer #{n}" }
    position { 0 }
  end
end
