puts "  Creating study sessions..."

demo       = User.find_by!(email_address: "demo@quizly.test")
ruby_deck  = demo.decks.find_by!(name: "Ruby Basics")
js_deck    = demo.decks.find_by!(name: "JavaScript Basics")
fr_deck    = demo.decks.find_by!(name: "French Vocabulary")

sessions = [
  { deck: ruby_deck, days_ago: 7, total: 5, reviewed: 5, correct: 3, duration_min: 6 },
  { deck: ruby_deck, days_ago: 6, total: 5, reviewed: 5, correct: 5, duration_min: 4 },
  { deck: js_deck,   days_ago: 5, total: 5, reviewed: 4, correct: 3, duration_min: 7 },
  { deck: ruby_deck, days_ago: 4, total: 5, reviewed: 5, correct: 4, duration_min: 5 },
  { deck: fr_deck,   days_ago: 2, total: 8, reviewed: 8, correct: 6, duration_min: 8 },
  { deck: js_deck,   days_ago: 1, total: 5, reviewed: 5, correct: 5, duration_min: 4 }
].freeze

sessions.each do |s|
  started = s[:days_ago].days.ago.change(hour: 20, min: 0, sec: 0)
  StudySession.find_or_create_by!(user: demo, deck: s[:deck], started_at: started) do |ss|
    ss.finished_at    = started + s[:duration_min].minutes
    ss.cards_total    = s[:total]
    ss.cards_reviewed = s[:reviewed]
    ss.cards_correct  = s[:correct]
  end
end

puts "    #{StudySession.count} study sessions"
