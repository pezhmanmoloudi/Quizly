FactoryBot.define do
  factory :deck do
    association :user
    sequence(:name) { |n| "Deck #{n}" }
    description { "A test deck" }
    visibility { "private" }

    trait :public do
      visibility { "public" }
    end

    trait :with_cards do
      after(:build) do |deck|
        deck.flashcards.build(front_content: "Q1", back_content: "A1", position: 1)
        deck.flashcards.build(front_content: "Q2", back_content: "A2", position: 2)
      end
      after(:create) do |deck|
        deck.flashcards.create!(front_content: "Q1", back_content: "A1", position: 1) if deck.flashcards.empty?
        deck.flashcards.create!(front_content: "Q2", back_content: "A2", position: 2) if deck.flashcards.count < 2
      end
    end
  end
end
