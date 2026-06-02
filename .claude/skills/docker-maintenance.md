# Docker Maintenance Guide — Quizly

Rails 8 · PostgreSQL · Importmap · Stimulus · Solid Queue · Active Storage

---

## How the stack reloads

Understanding what triggers what prevents unnecessary rebuilds.

| Mechanism | What it covers | How it works |
|-----------|---------------|--------------|
| **Rails code reload** | `app/**`, `config/routes.rb`, most of `config/` | `config.enable_reloading = true` in development; Rails watches the file system and reloads changed constants between requests. No restart needed. |
| **Container restart** | `config/initializers/**`, `config/puma.rb`, `config/database.yml`, `config/environments/**`, env vars | Initializers and Puma config run once at boot. Rails must be restarted (not rebuilt) to pick up changes. |
| **Image rebuild** | `Gemfile`, `Gemfile.lock`, `Dockerfile.dev`, system packages | Gems and native extensions are compiled during `docker compose build`. A new layer is required. |
| **Migration** | `db/migrate/**` | Schema changes require `rails db:migrate`. On next `docker compose up` the entrypoint runs `db:prepare` automatically, so restarting the container is sufficient. |

---

## Decision matrix

### Application code — no restart, no rebuild

| Path | Rebuild? | Restart? | Migrate? | Notes |
|------|----------|----------|----------|-------|
| `app/models/**` | No | No | Maybe | If the change adds a column, also add a migration |
| `app/controllers/**` | No | No | No | |
| `app/views/**` | No | No | No | |
| `app/helpers/**` | No | No | No | |
| `app/mailers/**` | No | No | No | |
| `app/jobs/**` | No | No | No | Solid Queue workers pick up reloaded job classes without restart |
| `app/services/**` | No | No | No | |
| `app/channels/**` | No | No | No | `cable.yml` uses `async` adapter in development |
| `app/assets/stylesheets/**` | No | No | No | Propshaft serves assets directly from disk in development |
| `app/javascript/controllers/**` | No | No | No | Importmap serves files directly from disk; browser refresh is enough |
| `app/javascript/application.js` | No | No | No | Same — served from disk via importmap |
| `config/routes.rb` | No | No | No | Reloaded between requests |
| `config/importmap.rb` | No | **Yes** | No | Importmap pins are evaluated at boot; restart required to add or remove pins |
| `config/locales/**` | No | No | No | Reloaded with code |

### Configuration — restart required, no rebuild

| Path | Rebuild? | Restart? | Migrate? | Notes |
|------|----------|----------|----------|-------|
| `config/initializers/**` | No | **Yes** | No | Run once at process start |
| `config/environments/development.rb` | No | **Yes** | No | |
| `config/environments/production.rb` | No | **Yes** | No | Only affects production container |
| `config/puma.rb` | No | **Yes** | No | Puma re-reads config only on restart |
| `config/database.yml` | No | **Yes** | No | Connection pool changes take effect on restart |
| `config/queue.yml` | No | **Yes** | No | Solid Queue supervisor reads this at boot |
| `config/cache.yml` | No | **Yes** | No | Cache store is configured at boot |
| `config/cable.yml` | No | **Yes** | No | |
| `config/recurring.yml` | No | **Yes** | No | Solid Queue schedules load at supervisor boot |
| `config/storage.yml` | No | **Yes** | No | Active Storage service config |
| `config/credentials.yml.enc` | No | **Yes** | No | Credentials are read at boot |
| `config/master.key` | No | **Yes** | No | Key is read at boot; must exist or `RAILS_MASTER_KEY` must be set |
| `docker-compose.yml` (env vars only) | No | **Yes** | No | Stop and re-up to apply new env vars |

### Infrastructure — rebuild required

| Path | Rebuild? | Restart? | Migrate? | Notes |
|------|----------|----------|----------|-------|
| `Gemfile` | **Yes** | — | Maybe | Always pair with `Gemfile.lock` update |
| `Gemfile.lock` | **Yes** | — | Maybe | |
| `Dockerfile.dev` | **Yes** | — | No | System package changes, Ruby version, ENTRYPOINT changes |
| `docker-compose.yml` (volumes / build config) | **Yes** | — | No | Changes to `build:`, `volumes:`, service topology require rebuild or at minimum `down`/`up` |
| `.ruby-version` | **Yes** | — | No | Must match `ARG RUBY_VERSION` in `Dockerfile.dev` |

**Rebuild command:**
```bash
docker compose build web
docker compose up
```
Or in one step: `docker compose up --build`

**After adding gems only** — rebuild installs gems into the image layer, but the `bundle_cache` named volume shadows `/usr/local/bundle` in the running container. You must also populate the volume:
```bash
docker compose build web
docker compose run --rm web bundle install
docker compose up
```

### Database — migration required

| Path | Rebuild? | Restart? | Migrate? | Notes |
|------|----------|----------|----------|-------|
| `db/migrate/**` (new file) | No | No | **Yes** | `docker compose up` triggers `db:prepare` automatically via the entrypoint, which runs pending migrations |
| `db/schema.rb` | No | No | No | Auto-generated; never edit manually |
| `db/seeds.rb` | No | No | No | Seeds do not run automatically; run manually: `docker compose exec web bin/rails db:seed` |

---

## Minimum-action checklist

After making a change, answer these questions in order and stop at the first match.

```
1. Did you add, remove, or update a gem in Gemfile?
   → docker compose build web
   → docker compose run --rm web bundle install
   → docker compose up
   Stop here.

2. Did you change Dockerfile.dev, .ruby-version, or a system package dependency?
   → docker compose build web
   → docker compose up
   Stop here.

3. Did you add a new migration file?
   → docker compose up
     (entrypoint runs db:prepare automatically)
   Stop here.

4. Did you change an initializer, puma.rb, database.yml, queue.yml,
   cache.yml, cable.yml, recurring.yml, storage.yml, importmap.rb,
   or any config/environments/* file?
   → docker compose restart web
   Stop here.

5. Did you change docker-compose.yml environment variables?
   → docker compose stop web && docker compose up web
   Stop here.

6. Did you change anything in app/**, config/routes.rb, or config/locales/**?
   → Refresh the browser.
   Stop here.
```

---

## Project-specific exceptions

### importmap.rb is a restart, not a browser-refresh
Unlike other `app/` files, `config/importmap.rb` is evaluated at boot. Adding or removing a `pin` or `pin_all_from` requires restarting the container. The JS files themselves (`app/javascript/**`) are served from disk and do not require restart.

### Solid Queue tables live in the primary database (development only)
Production uses a dedicated `queue` SQLite database (`storage/production_queue.sqlite3`) with its own `db/queue_migrate/` path. In development, Solid Queue tables are in the primary PostgreSQL database (`db/migrate/`). A migration affecting Solid Queue tables only needs `db:migrate` — no separate database command.

### bundle_cache volume shadows the image bundle
The named volume `bundle_cache` is mounted at `/usr/local/bundle`, which is the same path where `docker compose build` installs gems. After a rebuild, new gems are in the image layer but NOT visible in the running container until `bundle install` is run inside the container to populate the volume. See checklist item 1.

### config/master.key is bind-mounted, not baked in
`config/master.key` is gitignored but present on disk and bind-mounted into the container (`- .:/rails`). A change to this file takes effect on container restart with no rebuild. If the file is absent, set `RAILS_MASTER_KEY` in `.env`.

### Active Storage uses libvips (not ImageMagick)
`User#has_one_attached :avatar` uses image variants. The `libvips` system library is installed in `Dockerfile.dev`. If you switch to ImageMagick, update `Dockerfile.dev` and rebuild.

### No Webpack, no Node, no asset pipeline compilation step
This project uses Propshaft (not Sprockets) and Importmap (not Webpack). There is no `yarn install`, no `npm ci`, and no `assets:precompile` step in development. CSS and JS files are served directly from disk. Changes are instant on browser refresh.

### No system tests (Capybara/Selenium)
No browser driver is installed in `Dockerfile.dev`. Do not add Capybara/Selenium without first adding the required system packages to the dev image and rebuilding.

---

## Quick reference card

```
Change type                   → Minimum action
─────────────────────────────────────────────────────
app/**  /  config/routes.rb   → browser refresh
config/initializers/**        → docker compose restart web
config/importmap.rb           → docker compose restart web
config/environments/**        → docker compose restart web
config/puma.rb                → docker compose restart web
config/queue.yml              → docker compose restart web
config/database.yml           → docker compose restart web
New migration                 → docker compose up (auto)
Gemfile / Gemfile.lock        → build + bundle install + up
Dockerfile.dev / .ruby-version→ build + up
docker-compose.yml env vars   → stop + up
```
