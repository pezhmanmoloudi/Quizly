puts "  Creating badges..."

badge_defs = [
  { key: "first_session", name: "First Session",   description: "Complete your first study session",   icon: "🎯", category: "streak"   },
  { key: "streak_3",      name: "On a Roll",        description: "Study 3 days in a row",               icon: "🔥", category: "streak"   },
  { key: "streak_7",      name: "Weekly Warrior",   description: "Study 7 days in a row",               icon: "⚡", category: "streak"   },
  { key: "streak_30",     name: "Monthly Master",   description: "Study 30 days in a row",              icon: "🏆", category: "streak"   },
  { key: "streak_100",    name: "Centurion",         description: "Study 100 days in a row",             icon: "💎", category: "streak"   },
  { key: "cards_10",      name: "Getting Started",  description: "Review 10 cards",                     icon: "📚", category: "cards"    },
  { key: "cards_100",     name: "Dedicated",         description: "Review 100 cards",                    icon: "🎓", category: "cards"    },
  { key: "cards_500",     name: "Powerhouse",        description: "Review 500 cards",                    icon: "🚀", category: "cards"    },
  { key: "cards_1000",    name: "Legend",            description: "Review 1000 cards",                   icon: "🌟", category: "cards"    },
  { key: "perfect_test",  name: "Sharpshooter",      description: "Score 100% on a test session",        icon: "🎯", category: "accuracy" }
].freeze

badge_defs.each do |attrs|
  Badge.find_or_create_by!(key: attrs[:key]) do |b|
    b.name        = attrs[:name]
    b.description = attrs[:description]
    b.icon        = attrs[:icon]
    b.category    = attrs[:category]
  end
end

puts "    #{Badge.count} badges"
