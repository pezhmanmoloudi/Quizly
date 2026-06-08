# Database

## Environment Strategy

**Development + Test:** SQLite — zero-config, no external service, fast for local work.

**Production:** Configurable via `DATABASE_URL` environment variable.
- SQLite: suitable for low-traffic or single-server deployments
- PostgreSQL: recommended when concurrent writes, replication, or managed DB services are required

Do not hard-code the production database adapter in application code. Keep the adapter choice a deployment decision.

## Rules

- Use foreign keys on all associations
- Add indexes intentionally — every foreign key, every column used in WHERE or ORDER
- Avoid duplicated data — normalize the schema
- Keep schema simple and readable

## Migrations

- Write reversible migrations (use `change` with reversible operations, or explicit `up`/`down`)
- Make incremental, small changes — one concern per migration
- Never modify existing migrations that have been run in production

## Performance

- Avoid N+1 queries — use `includes`, `preload`, or `eager_load` where associations are accessed
- Paginate large collections — never load unbounded result sets
- Use `select` to limit columns when fetching for display only

Optimize only when a measurable performance issue exists.
