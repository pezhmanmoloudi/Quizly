# Quizly

A flashcard learning platform built with Rails 8. Create decks, add cards, and study with five distinct modes — from simple card flipping to adaptive quizzes and spaced repetition.

---

## Study Modes

| Mode | Description |
|------|-------------|
| **Flashcard** | Browse and flip cards at your own pace |
| **Study** | Spaced repetition using the SM-2 algorithm — due cards are served based on your performance history |
| **Learn** | Progressive mastery — incorrectly answered cards are re-queued until you get them right |
| **Test** | Adaptive quiz with multiple choice, written answer, and true/false question types |
| **Match** | Pair-matching game using 8 randomly selected cards from the deck |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Ruby 3.3.5 |
| Framework | Rails 8.1.3 |
| Database (local) | SQLite3 |
| Database (Docker) | PostgreSQL 16 |
| Frontend | Hotwire (Turbo + Stimulus) |
| Asset pipeline | Propshaft + Importmap — no Node.js required |
| Authentication | bcrypt (`has_secure_password`) |
| File uploads | Active Storage |
| Pagination | Pagy |
| Background jobs | Solid Queue (default) |
| Caching | Solid Cache |
| Action Cable | Solid Cable |
| Testing | RSpec 8 + FactoryBot + Faker |
| Linting | Rubocop (rails-omakase) |
| Security scanning | Brakeman |
| CI | GitHub Actions |
| Deployment | Kamal + Docker |

---

## Features

- User registration, login, logout, and password reset via email token
- User profile with display name and avatar upload (JPG/PNG/WEBP, 5 MB max)
- Deck creation, editing, and deletion with public/private visibility
- Flashcard management with position ordering
- Five study modes: Flashcard, Study, Learn, Test, Match
- Spaced repetition tracking per user per card (SM-2 algorithm)
- Starred cards and starred-only study filter
- Study session history with accuracy metrics
- Explore page to discover public decks, searchable and sortable by popularity
- Fork any public deck into your own library
- Bulk card import via CSV (auto-detect columns) or tab-delimited text
- Rate-limited login (10 attempts per 3 minutes)

---

## Prerequisites

**Docker path (recommended)**
- Docker Desktop 4.x or Docker Engine 24+ with Compose v2
- `config/master.key` — ask a teammate or retrieve from your secrets manager

**Local path (without Docker)**
- Ruby 3.3.5 — install via [rbenv](https://github.com/rbenv/rbenv), [rvm](https://rvm.io), or [asdf](https://asdf-vm.com)
- SQLite3 and libvips system libraries (see Local Setup below)
- `config/master.key` — same as above

---

## Quick Start — Docker

```bash
git clone <repo-url>
cd quizly

# Create your local environment file
cp .env.example .env
# Open .env and set RAILS_MASTER_KEY to the value from config/master.key

# Build and start all services
docker compose up --build
```

The app is available at **http://localhost:3001**

```bash
# Load demo data (first time only)
docker compose exec web bin/rails db:seed
```

**Demo account**

| Field | Value |
|-------|-------|
| Email | `demo@quizly.test` |
| Password | `password123` |

Three sample decks (Ruby Basics, JavaScript Basics, French Vocabulary) are included.

See [DOCKER.md](DOCKER.md) for the full Docker reference including daily workflow, full reset, and troubleshooting.

---

## Local Development Setup

Use this path if you prefer to run Rails directly without Docker. The app uses SQLite3 locally — no PostgreSQL or Redis required.

**1. Install system dependencies**

```bash
# macOS
brew install sqlite3 vips

# Ubuntu / Debian
sudo apt install libsqlite3-dev libvips-dev
```

**2. Install Ruby 3.3.5**

```bash
# rbenv
rbenv install 3.3.5
rbenv local 3.3.5

# rvm
rvm install 3.3.5

# asdf
asdf install ruby 3.3.5
asdf local ruby 3.3.5
```

**3. Install gems**

```bash
bundle install
```

**4. Configure environment**

```bash
cp .env.example .env
# Open .env and set RAILS_MASTER_KEY to the value from config/master.key
```

**5. Set up the database**

```bash
bin/rails db:create db:migrate db:seed
```

**6. Start the server**

```bash
bin/rails server
```

The app is available at **http://localhost:3000**

Log in with `demo@quizly.test` / `password123`.

---

## Running Tests

```bash
# Full test suite
bundle exec rspec

# By layer
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/services

# Code style
bin/rubocop

# Security scan
bin/brakeman --no-pager
```

**CI pipeline** — GitHub Actions runs three checks automatically on every PR and push to `main`:

| Check | Command |
|-------|---------|
| Security scan | `bin/brakeman --no-pager` |
| JS dependency audit | `bin/importmap audit` |
| Style lint | `bin/rubocop -f github` |

RSpec is not run in CI. Run the test suite locally before opening a pull request.

---

## Further Reading

| Document | Contents |
|----------|----------|
| [DOCKER.md](DOCKER.md) | Full Docker workflow, daily commands, architecture notes |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Data model, study mode internals, services, Stimulus controllers |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Kamal deployment guide, production environment variables |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | PR workflow, code conventions, test patterns |
