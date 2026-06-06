# Deployment

Quizly is deployed with [Kamal](https://kamal-deploy.org), which packages the app as a Docker image and manages rolling deploys to any Docker-capable host.

---

## Prerequisites

On your **local machine:**
- Kamal CLI: `gem install kamal` (or it is included in the bundle)
- Docker (for building the image)
- SSH access to the target server

On the **target server:**
- Docker Engine 24+ installed
- Port 80 and 443 open
- A domain name pointing to the server's IP

---

## Configure deploy.yml

`config/deploy.yml` ships with placeholder values that must be replaced before the first deploy.

| Placeholder | Replace with |
|-------------|-------------|
| `your-user/quizly` (image) | Your Docker Hub username and image name, e.g. `acme/quizly` |
| `your-user` (registry username) | Your Docker Hub username |
| `192.168.0.1` (server IP) | The actual IP address of your production server |
| `app.example.com` (SSL host) | Your domain name |

---

## Configure .kamal/secrets

`.kamal/secrets` references the secrets Kamal injects into the container at deploy time. Edit it to pull values from your password manager or CI environment:

```bash
KAMAL_REGISTRY_PASSWORD=$(op read "op://vault/docker-hub/password")
RAILS_MASTER_KEY=$(cat config/master.key)
```

Adjust the retrieval commands to match your secrets manager.

---

## Required Production Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `RAILS_MASTER_KEY` | Yes | Decrypts `config/credentials.yml.enc` |
| `MAILER_HOST` | Recommended | Hostname used in Action Mailer link generation |
| `RAILS_LOG_LEVEL` | Optional | Default: `info` |
| `SOLID_QUEUE_IN_PUMA` | Optional | Default: `true` (set in deploy.yml) |

Production uses SQLite3 — no `DATABASE_URL` or `REDIS_URL` required unless you switch adapters.

---

## First Deploy

```bash
# Push the image and start the server
bin/kamal deploy

# Run seeds on the production database (first time only, if needed)
bin/kamal app exec 'bin/rails db:seed'
```

---

## Common Commands

```bash
bin/kamal deploy          # build, push image, rolling restart
bin/kamal rollback        # revert to the previous image
bin/kamal app logs -f     # tail production logs
bin/kamal app exec 'bin/rails console'   # production Rails console
bin/kamal app exec 'bash'                # shell on the running container
```

Or use the configured Kamal aliases:

```bash
bin/kamal console         # Rails console
bin/kamal shell           # bash
bin/kamal logs            # tail logs
bin/kamal dbc             # Rails dbconsole
```

---

## Production Database

The production environment uses four SQLite3 databases, all stored in the `quizly_storage` Docker volume mounted at `/rails/storage`:

| Database file | Purpose |
|---------------|---------|
| `production.sqlite3` | Primary application database |
| `production_cache.sqlite3` | Solid Cache |
| `production_queue.sqlite3` | Solid Queue |
| `production_cable.sqlite3` | Solid Cable |

The volume is defined in `config/deploy.yml`:

```yaml
volumes:
  - "quizly_storage:/rails/storage"
```

Back up this volume to preserve application data across server replacements.

---

## Production Security Notes

- SSL is enforced via `config.force_ssl = true`
- The app runs as a non-root user (UID/GID 1000) inside the container
- Thruster handles HTTP asset caching and X-Sendfile acceleration in front of Puma
- Let's Encrypt certificates are managed automatically by the Kamal proxy
