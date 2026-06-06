FactoryBot.define do
  factory :test_session do
    association :user
    association :deck
    questions_data  { [ { "flashcard_id" => 1, "type" => "written", "prompt" => "Q?",
                          "correct_answer" => "A", "options" => [] } ].to_json }
    questions_total { 1 }
    current_index   { 0 }
    score           { 0 }
    started_at      { Time.current }
    finished_at     { nil }

    trait :completed do
      score       { 1 }
      finished_at { Time.current }
    end
  end
end
