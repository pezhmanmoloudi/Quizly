Spaced Repetition Engine

ALGORITHM:
- simplified SM-2

CARD STATES:
- new
- learning
- review
- mastered

RULES:
- each answer updates next_review_at
- only fetch due cards
- avoid full recomputation

PERFORMANCE:
- index next_review_at
- optimize due queries

IMPORTANT:
This is core learning engine of Quizly.