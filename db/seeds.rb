puts "== Seeding Quizly demo data =="

Dir[File.join(__dir__, "seeds", "*.rb")].sort.each do |file|
  puts "-> #{File.basename(file)}"
  load file
end

puts ""
puts "== Done =="
puts "  Users:          #{User.count}"
puts "  Decks:          #{Deck.count}"
puts "  Flashcards:     #{Flashcard.count}"
puts "  Study sessions: #{StudySession.count}"
puts "  Badges:         #{Badge.count}"
puts ""
puts "  Demo login:  demo@quizly.test / password123"
