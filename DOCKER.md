# Docker Development Setup

Run Quizly locally with Docker Compose using **PostgreSQL** and **Redis**.
Non-Docker local development continues to use SQLite unchanged.

## Prerequisites

- Docker Desktop 4.x or Docker Engine 24+ with Compose v2

`config/master.key` is **not required** for local development. A secret key is auto-generated in `tmp/development_secret.txt` on first boot.

## First-Time Setup

**1. Create your `.env` file**

```bash
cp .env.example .env
```

No changes to `.env` are needed for local development — the file is ready to use as-is.

**2. Build and start the application**

```bash
docker compose up --build
```

The app is available at **http://localhost:3001**

The database schema is created and migrated automatically on startup. Seed data requires one manual step (step 3 below).

Stop with `Ctrl+C`. To run in the background: `docker compose up -d`

**3. Load demo data (recommended for first-time setup)**

```bash
docker compose exec web bin/rails db:seed
```

This creates a demo account and sample decks so you can explore all study modes immediately.

| Credential | Value |
|------------|-------|
| Email | `demo@quizly.test` |
| Password | `password123` |

---

## Daily Workflow

| Task | Command |
|------|---------|
| Start services | `docker compose up` |
| Start in background | `docker compose up -d` |
| Stop services | `docker compose down` |
| View logs | `docker compose logs -f web` |
| Rails console | `docker compose exec web bin/rails console` |
| Run migrations | `docker compose exec web bin/rails db:migrate` |
| Run tests | `docker compose exec web bundle exec rspec` |
| Open bash shell | `docker compose exec web bash` |

---

## Adding or Changing Gems

After modifying `Gemfile`:

```bash
docker compose build
```

The container entrypoint (`bin/docker-entrypoint`) runs `bundle check || bundle install` on each startup — a rebuild is sufficient. The `bundle_cache` named volume persists gems across container restarts.

---

## Architecture Notes

### DATABASE_URL and SQLite

`docker-compose.yml` sets `DATABASE_URL=postgresql://...` which Rails uses in place of the SQLite config in `database.yml`. Local developers without Docker continue using SQLite at `storage/development.sqlite3` — the two environments are fully isolated. No changes were made to `database.yml`.

### Solid Queue vs Sidekiq

Quizly uses **Solid Queue** as its Active Job adapter. The `sidekiq` and `redis` gems are included in the bundle for optional use, but the Active Job adapter is not changed. Solid Queue processes all jobs by default.

The Solid Queue supervisor starts inside Puma via `SOLID_QUEUE_IN_PUMA=true` — no separate worker container is needed.

### Production vs Development Dockerfiles

| File | Purpose |
|------|---------|
| `Dockerfile` | Production builds — used by Kamal for deployment |
| `Dockerfile.dev` | Development builds — used by `docker-compose.yml` |

Do **not** use `Dockerfile.dev` for production.

---

## Full Reset

Wipe all Docker state and start fresh:

```bash
docker compose down -v          # remove containers and named volumes
docker compose up --build
```

The database is recreated and all migrations are applied automatically on the first startup.
