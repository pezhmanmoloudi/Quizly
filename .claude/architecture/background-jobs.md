Background Jobs Rules

SYSTEM:
- Sidekiq
- Redis

USE CASES:
- quiz generation
- email sending
- analytics
- heavy computations

RULES:
- idempotent jobs
- retry-safe
- no business logic inside jobs
- call services instead

IMPORTANT:
Jobs are for async execution only.