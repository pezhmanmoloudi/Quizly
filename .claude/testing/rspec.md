RSpec Rules (Quizly)

TESTING PHILOSOPHY:
- test behavior, not implementation
- focus on business logic
- avoid testing Rails internals

TEST LEVELS:

- Model specs → validations + domain logic
- Request specs → API endpoints
- System specs → user flows (Hotwire UI)
- Job specs → background processing

RULES:
- use factories
- isolate test cases
- test edge cases
- test validations

SYSTEM TESTS:
- study flow end-to-end
- Turbo interactions

ANTI-PATTERN:
- do not test framework behavior
- do not over-test simple Rails features

IMPORTANT:
Tests ensure long-term maintainability and safe refactoring.