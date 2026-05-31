Engineering Philosophy (Quizly)

CORE PRINCIPLE:
Simplicity first. Rails conventions first. Optimize only when necessary.

------------------------------------

SYSTEM GOALS:

- production-ready Rails monolith
- maintainable and readable codebase
- fast iteration for MVP development
- scalable learning platform (Quizly)
- strong test coverage for business logic

------------------------------------

ARCHITECTURE PRINCIPLES:

- separation of concerns (lightweight, not over-engineered)
- small and focused files
- feature-based structure (Decks, Flashcards, Study, Users)
- Rails MVC as core architecture
- service objects only for complex workflows
- avoid unnecessary abstraction layers

------------------------------------

AI CODING PHILOSOPHY:

- avoid overengineering
- prefer Rails conventions over custom patterns
- generate simple and predictable code
- optimize only when there is real performance need
- MVP-first thinking, production-ready when scaling

------------------------------------

FRONTEND PHILOSOPHY (HOTWIRE):

- Hotwire (Turbo + Stimulus) is primary UI system
- server-rendered UI (no SPA framework)
- Turbo Frames for partial updates
- Turbo Streams for real-time updates
- mobile-first design
- minimal and fast UI interactions

------------------------------------

BACKEND PHILOSOPHY:

- thin controllers (or simple controllers for MVP)
- models contain core domain logic
- service objects only for complex workflows
- RESTful Rails design where needed
- clear and explicit business logic

------------------------------------

PROJECT TYPE:

Quizly - Flashcard Learning Platform

CORE FEATURES:

- spaced repetition system
- deck management
- flashcards system
- study sessions
- quizzes and tests
- progress tracking
- optional media support (audio/image)

------------------------------------

IMPORTANT RULE:

Prefer simplicity over abstraction.
If unsure, choose the simplest Rails solution.