Coding Standards (Quizly)

GENERAL RULES:

- Keep files small and focused
- Prefer clarity over cleverness
- Avoid unnecessary abstractions
- Use descriptive names
- Write self-documenting code

------------------------------------

NAMING RULES:

- Classes: PascalCase
- Services: XxxService
- Files: kebab-case
- Methods: snake_case
- Models: singular nouns

------------------------------------

FORMATTING RULES:

- Consistent indentation
- Remove dead code
- Remove unused imports
- Avoid long methods/functions

------------------------------------

FRONTEND RULES (HOTWIRE):

- Use Turbo Frames for partial updates
- Use Turbo Streams for real-time updates
- Use Stimulus controllers for interactivity
- Avoid SPA patterns (no Vue/React mindset)
- Keep UI minimal and server-driven

------------------------------------

BACKEND RULES:

- Thin controllers
- Business logic in models (simple cases)
- Use service objects only for complex workflows
- Use scopes for reusable queries
- Keep models focused and clean

------------------------------------

TESTING RULES:

- Test behavior, not implementation
- Cover edge cases
- Test error states
- Tests are mandatory for critical logic

------------------------------------

GIT RULES:

- Small commits
- Descriptive commit messages
- One feature per branch

------------------------------------

IMPORTANT:

Code should be:
- easy to read
- easy to modify
- easy for future developers to understand