user = User.find_or_create_by!(email_address: "demo@quizly.test") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

# ── Deck 1: Ruby Basics ──────────────────────────────────────────────
deck = user.decks.find_or_create_by!(name: "Ruby Basics") do |d|
  d.description = "Fundamental Ruby concepts"
  d.visibility  = "public"
end
deck.update_columns(visibility: "public") if deck.visibility != "public"

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

# ── Deck 2: JavaScript Basics ────────────────────────────────────────
js_deck = user.decks.find_or_create_by!(name: "JavaScript Basics") do |d|
  d.description = "Core JavaScript concepts every developer should know."
  d.visibility  = "public"
end
js_deck.update_columns(visibility: "public") if js_deck.visibility != "public"

js_cards = [
  { front_content: "What is `typeof null` in JavaScript?",
    back_content: '"object" — a historical bug in the language that was never fixed.' },
  { front_content: "What does `===` check vs `==`?",
    back_content: '`===` checks value AND type (strict equality). `==` allows type coercion.' },
  { front_content: "What is a closure?",
    back_content: "A function that retains access to variables from its enclosing scope even after that scope has returned." },
  { front_content: "What does `Array.prototype.map` return?",
    back_content: "A new array with each element transformed by the provided callback." },
  { front_content: "What is `undefined` vs `null`?",
    back_content: "`undefined` means a variable has been declared but not assigned. `null` is an intentional absence of value." }
]

js_cards.each.with_index(1) do |attrs, i|
  js_deck.flashcards.find_or_create_by!(front_content: attrs[:front_content]) do |fc|
    fc.back_content = attrs[:back_content]
    fc.position = i
  end
end

# ── Deck 3: French Vocabulary ────────────────────────────────────────
fr_deck = user.decks.find_or_create_by!(name: "French Vocabulary") do |d|
  d.description = "Everyday French words and phrases for beginners."
  d.visibility  = "public"
  d.language_code = "fr"
end
fr_deck.update_columns(visibility: "public") if fr_deck.visibility != "public"

fr_cards = [
  { front_content: "Bonjour",         back_content: "Hello / Good morning" },
  { front_content: "Merci",           back_content: "Thank you" },
  { front_content: "S'il vous plaît", back_content: "Please" },
  { front_content: "Où est...?",      back_content: "Where is...?" },
  { front_content: "Je m'appelle",    back_content: "My name is" }
]

fr_cards.each.with_index(1) do |attrs, i|
  fr_deck.flashcards.find_or_create_by!(front_content: attrs[:front_content]) do |fc|
    fc.back_content = attrs[:back_content]
    fc.position = i
  end
end

puts "Seeded: #{user.email_address} / password123"
puts "  #{Deck.where(visibility: 'public').count} public deck(s) total"
