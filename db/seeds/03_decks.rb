puts "  Creating decks and flashcards..."

demo   = User.find_by!(email_address: "demo@quizly.test")
alice  = User.find_by!(email_address: "alice@quizly.test")
bob    = User.find_by!(email_address: "bob@quizly.test")
carlos = User.find_by!(email_address: "carlos@quizly.test")
sarah  = User.find_by!(email_address: "sarah@quizly.test")
maria  = User.find_by!(email_address: "maria@quizly.test")

# ── Demo user ────────────────────────────────────────────────────────────────

seed_deck demo,
  name:        "Ruby Basics",
  description: "Fundamental Ruby concepts every developer should know.",
  visibility:  "public",
  cards: [
    { front: "What is a symbol in Ruby?",
      back:  "An immutable, reusable identifier, e.g. :name. Stored once in memory." },
    { front: "What does `freeze` do to an object?",
      back:  "Makes the object immutable — any mutation attempt raises FrozenError." },
    { front: "What is the difference between `nil?` and `empty?`?",
      back:  "`nil?` checks if the object is nil. `empty?` checks if a string/array/hash has no elements." },
    { front: "What does `attr_accessor` generate?",
      back:  "Both a getter and setter method for an instance variable." },
    { front: "What is a block in Ruby?",
      back:  "An anonymous chunk of code passed to a method using `do...end` or `{ }`." }
  ]

seed_deck demo,
  name:        "JavaScript Basics",
  description: "Core JavaScript concepts every developer should know.",
  visibility:  "public",
  cards: [
    { front: "What is `typeof null` in JavaScript?",
      back:  '"object" — a historical bug in the language that was never fixed.' },
    { front: "What does `===` check vs `==`?",
      back:  '`===` checks value AND type (strict equality). `==` allows type coercion.' },
    { front: "What is a closure?",
      back:  "A function that retains access to variables from its enclosing scope even after that scope has returned." },
    { front: "What does `Array.prototype.map` return?",
      back:  "A new array with each element transformed by the provided callback." },
    { front: "What is `undefined` vs `null`?",
      back:  "`undefined` means a variable was declared but not assigned. `null` is an intentional absence of value." }
  ]

seed_deck demo,
  name:        "French Vocabulary",
  description: "Everyday French words and phrases for beginners.",
  visibility:  "public",
  language_code: "fr",
  cards: [
    { front: "Bonjour",           back: "Hello / Good morning" },
    { front: "Merci",             back: "Thank you" },
    { front: "S'il vous plaît",   back: "Please" },
    { front: "Où est...?",        back: "Where is...?" },
    { front: "Je m'appelle",      back: "My name is" },
    { front: "Combien ça coûte?", back: "How much does it cost?" },
    { front: "Je ne comprends pas", back: "I don't understand" },
    { front: "Parlez-vous anglais?", back: "Do you speak English?" }
  ]

seed_deck demo,
  name:        "My Private Notes",
  description: "Personal study notes — work in progress.",
  visibility:  "private",
  cards: [
    { front: "What is memoization?",
      back:  "Caching the result of an expensive method call so it is computed only once." },
    { front: "What is the difference between `include` and `extend` in Ruby?",
      back:  "`include` adds module methods as instance methods; `extend` adds them as class methods." },
    { front: "What is N+1 query problem?",
      back:  "Loading a collection then making one extra query per record. Fixed with eager loading (includes/joins)." },
    { front: "What does `yield` do in Ruby?",
      back:  "Pauses the method and executes the block passed to it." }
  ]

# ── Alice ─────────────────────────────────────────────────────────────────────

seed_deck alice,
  name:        "Spanish Essentials",
  description: "Core Spanish vocabulary for absolute beginners.",
  visibility:  "public",
  language_code: "es",
  cards: [
    { front: "Hola",             back: "Hello" },
    { front: "Gracias",          back: "Thank you" },
    { front: "Por favor",        back: "Please" },
    { front: "¿Cómo te llamas?", back: "What is your name?" },
    { front: "Buenos días",      back: "Good morning" },
    { front: "¿Cuánto cuesta?",  back: "How much does it cost?" },
    { front: "No entiendo",      back: "I don't understand" },
    { front: "¿Dónde está...?",  back: "Where is...?" }
  ]

seed_deck alice,
  name:        "Travel Phrases",
  description: "Useful phrases for getting around in a foreign country.",
  visibility:  "public",
  cards: [
    { front: "Where is the nearest hotel?",
      back:  "¿Dónde está el hotel más cercano? / Où est l'hôtel le plus proche?" },
    { front: "I would like to check in.",
      back:  "Quisiera registrarme. / Je voudrais m'enregistrer." },
    { front: "Can I have the bill, please?",
      back:  "¿Me trae la cuenta, por favor? / L'addition, s'il vous plaît." },
    { front: "I have a reservation.",
      back:  "Tengo una reserva. / J'ai une réservation." },
    { front: "Where is the airport?",
      back:  "¿Dónde está el aeropuerto? / Où est l'aéroport?" },
    { front: "I need a taxi.",
      back:  "Necesito un taxi. / J'ai besoin d'un taxi." },
    { front: "Is there Wi-Fi here?",
      back:  "¿Hay Wi-Fi aquí? / Y a-t-il le Wi-Fi ici?" }
  ]

seed_deck alice,
  name:        "Personal Vocabulary",
  description: "Words I keep forgetting.",
  visibility:  "private",
  cards: [
    { front: "Ephemeral",  back: "Lasting for only a short time; transitory." },
    { front: "Ubiquitous", back: "Present, appearing, or found everywhere." },
    { front: "Pragmatic",  back: "Dealing with things sensibly and realistically." },
    { front: "Verbose",    back: "Using more words than needed; long-winded." },
    { front: "Iterate",    back: "Perform or utter repeatedly; go over again." }
  ]

# ── Bob ───────────────────────────────────────────────────────────────────────

seed_deck bob,
  name:        "Python Basics",
  description: "Core Python concepts for beginners coming from other languages.",
  visibility:  "public",
  cards: [
    { front: "What is a list comprehension?",
      back:  "[expr for item in iterable if condition] — creates a list in a single readable line." },
    { front: "What is the difference between a list and a tuple?",
      back:  "Lists are mutable (can be changed); tuples are immutable." },
    { front: "What does `*args` do in a function signature?",
      back:  "Collects all extra positional arguments into a tuple." },
    { front: "What does `**kwargs` do?",
      back:  "Collects all extra keyword arguments into a dictionary." },
    { front: "What is a decorator in Python?",
      back:  "A function that wraps another function to extend its behaviour without modifying it." },
    { front: "What is the GIL?",
      back:  "The Global Interpreter Lock — allows only one thread to execute Python bytecode at a time." }
  ]

seed_deck bob,
  name:        "SQL Essentials",
  description: "Key SQL concepts and query patterns for everyday use.",
  visibility:  "private",
  cards: [
    { front: "What is the difference between INNER JOIN and LEFT JOIN?",
      back:  "INNER JOIN returns only matching rows. LEFT JOIN returns all rows from the left table and matched rows from the right." },
    { front: "What does GROUP BY do?",
      back:  "Groups rows sharing a value in one or more columns so aggregate functions (COUNT, SUM) can be applied per group." },
    { front: "What is a subquery?",
      back:  "A query nested inside another query, used in SELECT, FROM, or WHERE clauses." },
    { front: "What does DISTINCT do?",
      back:  "Removes duplicate rows from the result set." },
    { front: "What is an index?",
      back:  "A data structure that speeds up row lookups on a column at the cost of additional storage and slower writes." }
  ]

# ── Carlos ────────────────────────────────────────────────────────────────────

seed_deck carlos,
  name:        "English Idioms",
  description: "Common English idioms and their meanings.",
  visibility:  "public",
  cards: [
    { front: "Break the ice",         back: "To do or say something to relieve tension in a social situation." },
    { front: "Hit the nail on the head", back: "To describe exactly what is causing a situation or problem." },
    { front: "Bite the bullet",       back: "To endure a painful or difficult situation that is unavoidable." },
    { front: "Under the weather",     back: "Feeling ill or unwell." },
    { front: "Spill the beans",       back: "To reveal secret information accidentally or indiscreetly." },
    { front: "On the fence",          back: "Undecided about something; neutral." }
  ]

seed_deck carlos,
  name:        "Business English",
  description: "Professional English phrases and vocabulary for the workplace.",
  visibility:  "unlisted",
  cards: [
    { front: "Circle back",           back: "To return to a topic or follow up on something discussed earlier." },
    { front: "Take this offline",     back: "To discuss something in a separate, private conversation rather than in a group meeting." },
    { front: "Synergy",               back: "The combined effect of working together that is greater than the sum of individual efforts." },
    { front: "Bandwidth",             back: "Informal: the capacity or availability to handle a task (e.g. 'I don't have the bandwidth for that')." },
    { front: "Deliverable",           back: "A tangible or intangible output that must be produced as part of a project." }
  ]

# ── Sarah ─────────────────────────────────────────────────────────────────────

seed_deck sarah,
  name:        "German Basics",
  description: "Essential German phrases and vocabulary for travellers.",
  visibility:  "public",
  language_code: "de",
  cards: [
    { front: "Guten Morgen",           back: "Good morning" },
    { front: "Danke schön",            back: "Thank you very much" },
    { front: "Bitte",                  back: "Please / You're welcome" },
    { front: "Entschuldigung",         back: "Excuse me / Sorry" },
    { front: "Wo ist die Toilette?",   back: "Where is the toilet?" },
    { front: "Ich verstehe nicht",     back: "I don't understand" },
    { front: "Sprechen Sie Englisch?", back: "Do you speak English?" }
  ]

seed_deck sarah,
  name:        "Italian Phrases",
  description: "Beginner Italian for travel and dining.",
  visibility:  "private",
  language_code: "it",
  cards: [
    { front: "Buongiorno",            back: "Good morning / Good day" },
    { front: "Grazie mille",          back: "Thank you very much" },
    { front: "Il conto, per favore",  back: "The bill, please" },
    { front: "Dov'è la stazione?",    back: "Where is the train station?" },
    { front: "Non capisco",           back: "I don't understand" }
  ]

# ── Maria ─────────────────────────────────────────────────────────────────────

seed_deck maria,
  name:        "Japanese Hiragana",
  description: "Learn to read and write the 46 basic hiragana characters.",
  visibility:  "public",
  language_code: "ja",
  cards: [
    { front: "あ", back: "a" },
    { front: "い", back: "i" },
    { front: "う", back: "u" },
    { front: "え", back: "e" },
    { front: "お", back: "o" },
    { front: "か", back: "ka" },
    { front: "き", back: "ki" },
    { front: "く", back: "ku" }
  ]

seed_deck maria,
  name:        "Korean Basics",
  description: "Everyday Korean greetings and essential phrases.",
  visibility:  "private",
  language_code: "ko",
  cards: [
    { front: "안녕하세요",     back: "Hello (formal)" },
    { front: "감사합니다",     back: "Thank you (formal)" },
    { front: "죄송합니다",     back: "I'm sorry (formal)" },
    { front: "얼마예요?",      back: "How much is it?" },
    { front: "화장실이 어디예요?", back: "Where is the restroom?" }
  ]

puts "    #{Deck.count} decks, #{Flashcard.count} flashcards"
