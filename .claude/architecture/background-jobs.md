# Background Jobs

## Default System

**Solid Queue** — Rails-native, zero external dependencies, runs in the same process as the app.

All job code must use the **ActiveJob** interface exclusively. Never reference Solid Queue or Sidekiq internals in job classes. The adapter is a deployment decision, not a code decision.

## Decision: Solid Queue vs Sidekiq

Use **Solid Queue** (default) when:
- Standard async processing: emails, notifications, lightweight background tasks
- Development and test environments (always use Solid Queue here)
- Single-server or moderate-scale production deployment

Use **Sidekiq + Redis** only when:
- High-throughput processing is required (thousands of jobs per minute sustained)
- Distributed worker scaling across multiple servers is needed
- Redis is already part of the production infrastructure for other reasons

If none of those conditions apply, do not introduce Redis as a dependency.

## Use Cases

- Email sending
- Notifications
- Analytics processing
- Heavy computations (report generation, exports)

## Rules

- Jobs must be **idempotent** — safe to run more than once with the same input
- Jobs must be **retry-safe** — failures must not leave the system in a broken state
- No business logic inside jobs — delegate to service objects instead
- Jobs are for async execution coordination only
