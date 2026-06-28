puts "  Creating users..."

SEED_USERS = [
  { email_address: "demo@quizly.test",   password: "password123", display_name: "Demo User",      locale: "en" },
  { email_address: "alice@quizly.test",  password: "password123", display_name: "Alice Chen",     locale: "en" },
  { email_address: "bob@quizly.test",    password: "password123", display_name: "Bob Martinez",   locale: "en" },
  { email_address: "carlos@quizly.test", password: "password123", display_name: "Carlos Rivera",  locale: "es" },
  { email_address: "sarah@quizly.test",  password: "password123", display_name: "Sarah Johnson",  locale: "en" },
  { email_address: "maria@quizly.test",  password: "password123", display_name: "Maria Dupont",   locale: "fr" }
].freeze

SEED_USERS.each do |attrs|
  user = User.find_or_create_by!(email_address: attrs[:email_address]) do |u|
    u.password              = attrs[:password]
    u.password_confirmation = attrs[:password]
    u.display_name          = attrs[:display_name]
    u.locale                = attrs[:locale]
  end
  puts "    #{user.email_address}"
end
