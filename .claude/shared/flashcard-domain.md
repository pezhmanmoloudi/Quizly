
Flashcard Domain Rules (Quizly)

------------------------------------
CORE PURPOSE
------------------------------------

Flashcards are atomic learning units designed for:
- active recall
- spaced repetition
- long-term memory retention

------------------------------------
CORE ENTITY: FLASHCARD
------------------------------------

A Flashcard represents a single learning concept.

Structure:
- front_content
- back_content
- optional example_sentence
- optional media attachments

Rules:
- must represent ONE concept only
- must remain simple and atomic
- must not mix multiple ideas

------------------------------------
FLASHCARD BEHAVIOR
------------------------------------

- Flashcards are reviewed repeatedly over time
- Performance is tracked per user
- Difficulty adapts dynamically based on user responses

------------------------------------
CARD PROGRESS MODEL
------------------------------------

Tracks user learning state per card:

- repetition_count
- easiness_factor
- interval_days
- next_review_at

Rules:
- updated after each review
- drives scheduling system
- must be query optimized

------------------------------------
STUDY SESSION
------------------------------------

Represents a learning interaction session.

Tracks:
- reviewed_cards
- correctness rate
- session duration

Rules:
- lightweight
- focused on interaction, not storage logic

------------------------------------
QUIZ BEHAVIOR
------------------------------------

Purpose:
Reinforce memory through recall testing.

Rules:
- quizzes are derived from flashcards
- must focus on weak cards
- must remain short and focused

Types:
- recall
- multiple choice
- context-based

------------------------------------
IMPORTANT DOMAIN RULES
------------------------------------

- Flashcards must stay atomic
- Learning must be progressive
- System must adapt to user performance