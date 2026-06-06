FactoryBot.define do
  factory :learn_session_item do
    association :learn_session
    association :flashcard
    status         { "unseen" }
    attempts       { 0 }
    correct_streak { 0 }
    sequence(:position) { |n| n }
  end
end
