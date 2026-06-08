FactoryBot.define do
  factory :badge do
    sequence(:key)  { |n| "badge_#{n}" }
    sequence(:name) { |n| "Badge #{n}" }
    description { "A test badge" }
    icon        { "🏅" }
    category    { "streak" }
  end
end
