user = User.find_or_create_by!(email_address: "demo@quizly.test") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

deck = user.decks.find_or_create_by!(title: "Ruby Basics") do |d|
  d.description = "Fundamental Ruby concepts"
end

flashcards_data = [
  { front_content: "What is a symbol in Ruby?",
    back_content: "An immutable, reusable identifier, e.g. :name. Stored once in memory." },
  { front_content: "What does `freeze` do to an object?",
    back_content: "Makes the object immutable — any mutation attempt raises FrozenError." },
  { front_content: "What is the difference between `nil?` and `empty?`?",
    back_content: "`nil?` checks if the object is nil. `empty?` checks if a string/array/hash has no elements." },
  { front_content: "What does `attr_accessor` generate?",
    back_content: "Both a getter and setter method for an instance variable." },
  { front_content: "What is a block in Ruby?",
    back_content: "An anonymous chunk of code passed to a method using `do...end` or `{ }`." }
]

flashcards_data.each.with_index(1) do |attrs, i|
  deck.flashcards.find_or_create_by!(front_content: attrs[:front_content]) do |fc|
    fc.back_content = attrs[:back_content]
    fc.position = i
  end
end

puts "Seeded: #{user.email_address} / password123 — #{deck.title} with #{deck.flashcards.count} cards"
