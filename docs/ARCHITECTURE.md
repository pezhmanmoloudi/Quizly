# Architecture

Technical reference for the Quizly codebase.

---

## Data Model

### Core tables

| Table | Purpose |
|-------|---------|
| `users` | Accounts — email, bcrypt password digest, display name, avatar attachment |
| `sessions` | HTTP sessions — user_id, IP address, user agent |
| `decks` | Flashcard collections — name, description, visibility (public/private), language code, subject tags, fork counter |
| `flashcards` | Individual cards — front/back content, position ordering, belongs to deck |
| `card_progresses` | Per-user per-card spaced repetition state — ease factor, interval, repetitions, next review date, starred flag |
| `study_sessions` | Completed study session records — cards reviewed, cards correct, timestamps |
| `learn_sessions` | Progressive learn mode sessions — cards total/mastered, timestamps |
| `learn_session_items` | Individual card state within a learn session — status (unseen/learning/mastered), attempts, streak |
| `test_sessions` | Quiz mode sessions — serialized questions JSON, score, current index |

### Key relationships

- A `user` has many `decks`, `card_progresses`, `study_sessions`, `learn_sessions`, `test_sessions`
- A `deck` belongs to a `user`, has many `flashcards`; optionally belongs to a `forked_from` deck (self-referential)
- A `card_progress` belongs to both a `user` and a `flashcard` (unique constraint on the pair)
- A `learn_session` has many `learn_session_items`, each pointing to one `flashcard`

---

## Study Modes

### Study — Spaced Repetition (SM-2)

Implemented in `app/services/sm2_scheduler.rb`.

The SuperMemo 2 algorithm schedules card reviews based on recall quality. On each review the user rates recall on a 1–5 scale (mapped internally to 0–5 quality):

- **Quality ≥ 3** (successful): interval and ease factor increase
- **Quality < 3** (failed): interval resets to 1 day, repetitions reset to 0

Interval progression:
- 1st successful repetition → 1 day
- 2nd → 6 days
- Subsequent → `previous_interval × ease_factor` (rounded)

Ease factor formula: `EF' = max(1.3, EF + 0.1 − (5 − q) × (0.08 + (5 − q) × 0.02))`

`CardProgress` records track state per user per card. Cards are "due" when `next_review_at <= now`.

### Learn — Progressive Mastery

Implemented via `LearnSession` / `LearnSessionItem` models.

Cards begin as `unseen`, advance to `learning` on first attempt, and reach `mastered` after one correct answer (`MASTERY_THRESHOLD = 1`). Cards answered incorrectly are moved to the end of the queue (`learning` status). The session ends when all items reach `mastered`.

### Test — Adaptive Quiz

Question generation in `app/services/question_engine.rb`.

Three question types:
- **Multiple choice** — 1 correct answer + 3 random distractors. Requires at least 4 cards in the deck; falls back to other types if fewer are available.
- **Written** — free-text input, checked case-insensitively with whitespace normalization.
- **True/False** — card front paired with either the correct back (true) or a random other card's back (false).

Questions are generated once, serialized to JSON in `test_sessions.questions_data`, and stepped through with `current_index`.

### Flashcard — Browse Mode

No session tracking. Cards are paginated (5/10/15/20/30 per page). Front/back flip is handled by `flashcard_controller.js` (Stimulus).

### Match — Pair Game

Eight cards are randomly selected from the deck. The player clicks a term, then its definition. Correct pairs are locked; wrong selections flash red. The game ends when all pairs are matched.

---

## Services

| Service | File | Purpose |
|---------|------|---------|
| `Sm2Scheduler` | `app/services/sm2_scheduler.rb` | Calculates next interval and ease factor after a study rating |
| `QuestionEngine` | `app/services/question_engine.rb` | Generates multiple choice, written, and true/false questions |
| `CsvImporter` | `app/services/csv_importer.rb` | Parses CSV files with auto-detected front/back columns; bulk inserts cards |
| `TextImporter` | `app/services/text_importer.rb` | Parses tab-delimited (or custom-delimited) text; bulk inserts cards |

---

## Authentication

Session-based authentication built on Rails 8 conventions:

- `has_secure_password` (bcrypt) on the `User` model
- `Current.user` set from a `sessions` table record on each request
- Login is rate-limited: 10 attempts per 3 minutes per IP (Rails rate limiter)
- Password reset uses a signed token sent by email; token expires on use
- Most controllers require authentication; public deck views and the explore page are accessible without an account

---

## Stimulus Controllers

| Controller | Responsibility |
|------------|---------------|
| `flashcard_controller` | Front/back flip animation |
| `study_mode_controller` | Reveal card and keyboard shortcuts (Space to reveal, 1–4 to rate, Escape to exit) |
| `learn_mode_controller` | Text input submission (Enter to submit, Escape to exit) |
| `test_mode_controller` | Multiple choice and written answer handling |
| `match_controller` | Pair selection and game state |
| `card_editor_controller` | Inline card CRUD within deck view |
| `carousel_controller` | Deck carousel navigation |
| `sidebar_controller` | Sidebar open/close |
| `settings_tabs_controller` | Account settings tab switching |
| `avatar_preview_controller` | Live avatar upload preview |
| `password_toggle_controller` | Show/hide password fields |
| `flash_controller` | Flash message dismissal |
| `field_error_controller` | Field error highlighting |
| `import_controller` | Import form tab switching (CSV vs text) |
| `auto_submit_controller` | Auto-submit forms on input change |
| `inline_confirm_controller` | Two-step inline delete confirmation |

---

## Background Jobs

**Default adapter:** Solid Queue, running inside the Puma process (`SOLID_QUEUE_IN_PUMA=true`).

**Optional:** The `sidekiq` and `redis` gems are bundled but the Active Job adapter is not changed. Switch to Sidekiq by updating `config.active_job.queue_adapter` in the relevant environment file and providing a `REDIS_URL`.

In Docker development, a Redis service is included and `REDIS_URL` is set in `docker-compose.yml`. In local SQLite development, Redis is not required as Solid Queue uses SQLite.
