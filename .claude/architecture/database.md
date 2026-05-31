Database Rules

DB:
- PostgreSQL (production)
- SQLite (development)

RULES:
- Use foreign keys
- Add indexes intentionally
- Avoid duplicated data
- Keep schema simple

MIGRATIONS:
- reversible migrations
- small incremental changes

PERFORMANCE:
- avoid N+1 queries
- use includes/preload
- paginate large datasets

IMPORTANT:
Optimize only when needed.