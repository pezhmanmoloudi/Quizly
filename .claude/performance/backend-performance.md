Backend Performance Rules (Quizly)

CONTEXT:
Performance is critical for learning experience, especially in Study Mode and Spaced Repetition.

------------------------------------

QUERIES:
- avoid N+1 queries
- use includes/preload/eager_load
- paginate large collections
- use select to limit columns
- use counter_cache when possible

CRITICAL AREAS:
- study sessions
- deck loading
- spaced repetition queries

------------------------------------

CACHING:
- cache dashboard statistics
- cache deck summaries
- cache spaced repetition counts
- avoid unnecessary DB hits

------------------------------------

BACKGROUND JOBS:
- move heavy computations to Active Job (Solid Queue by default)
- avoid blocking requests
- keep jobs lightweight and focused
- background job adapter is configurable in production — see architecture/background-jobs.md

------------------------------------

MONITORING:
- log queries slower than 200ms
- detect N+1 queries
- monitor /study, /decks, /flashcards endpoints

------------------------------------

IMPORTANT:
Optimize only when there is a measurable performance issue.
Avoid premature optimization.