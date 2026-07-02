# Deployment (T03 + T16 + T17 + T18)

## Oracle Cloud VM setup

1. Clone repo to `/var/www/shikshaportal`
2. Configure secrets (T17 — never commit `.env`):
   ```bash
   cd /var/www/shikshaportal/backend
   cp .env.example .env
   # Edit .env — set DATABASE_URL, SECRET_KEY_BASE, JWT_SECRET_KEY, SUPER_ADMIN_API_KEY
   # Generate secrets: bundle exec rails secret
   bin/check-env
   ```
3. Install Ruby 3.2, Node 20, PostgreSQL client, Bundler
4. `cd backend && bundle install && RAILS_ENV=production rails db:prepare`
5. `cd frontend && npm ci && npm run build`
6. Install Puma systemd service: `sudo cp deploy/puma.service /etc/systemd/system/ && sudo systemctl enable --now puma`
7. Install Redis and Sidekiq (T23):
   ```bash
   sudo apt install redis-server
   sudo systemctl enable --now redis-server
   # Add REDIS_URL and SIDEKIQ_WEB_PASSWORD to backend/.env
   sudo cp deploy/sidekiq.service /etc/systemd/system/
   sudo systemctl enable --now sidekiq
   ```
8. Install Nginx: `bash deploy/install-nginx.sh`
8. Cloudflare: see `docs/cloudflare-dns.md`

## Environment variables (T17)

All secrets live in `backend/.env` on the server (loaded by `deploy/puma.service`). Templates:

| File | Use |
|------|-----|
| `backend/.env.example` | Local development |
| `backend/.env.staging.example` | Staging VM (separate DB + `APP_HOST`) |
| `frontend/.env.example` | Optional `VITE_API_URL` override |

### Required in production/staging

| Variable | How to set |
|----------|------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY_BASE` | `rails secret` |
| `JWT_SECRET_KEY` | `rails secret` (different value) |
| `SUPER_ADMIN_API_KEY` | Random string for school registration API |

### Optional

| Variable | Purpose |
|----------|---------|
| `APP_HOST` | Base domain (default `shikshaportal.in`) |
| `FRONTEND_ORIGIN` | CORS origin |
| `MAILER_FROM` | Email from address |
| `CURSOR_API_KEY` / `ANTHROPIC_API_KEY` | AI Parent Communicator |
| `R2_*` | Cloudflare R2 uploads (all four required together) |
| `REDIS_URL` | Redis connection for Sidekiq (e.g. `redis://localhost:6379/0`) |
| `SIDEKIQ_WEB_PASSWORD` | Protects `/sidekiq` web UI with HTTP basic auth |

Validate anytime: `cd backend && bin/check-env` or `RAILS_ENV=staging bin/check-env`.

**Never commit** `.env`, `config/master.key`, or API keys to git.

## GitHub Actions CI/CD (T16)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR to `main` | Backend tests + frontend build |
| `deploy.yml` | After CI succeeds on `main` | SSH deploy to Oracle Cloud |

Failed CI blocks deploy — deploy only runs when the CI workflow completes successfully.

### Required GitHub secrets

| Secret | Description |
|--------|-------------|
| `DEPLOY_HOST` | Oracle VM public IP |
| `DEPLOY_USER` | SSH user (e.g. `ubuntu`) |
| `DEPLOY_SSH_KEY` | Private key for deploy user (no passphrase) |

### Optional secrets

| Secret | Description |
|--------|-------------|
| `SLACK_WEBHOOK_URL` | Slack incoming webhook for deploy success/failure notifications |
| `SMOKE_ADMIN_PASSWORD` | Green Valley admin password for post-deploy smoke test (T18) |
| `SMOKE_STUDENT_PASSWORD` | Green Valley student password for post-deploy smoke test (T18) |

Configure secrets under **Settings → Secrets and variables → Actions**. Use the `production` environment for deploy approvals if desired.

### Manual deploy

```bash
ssh ubuntu@<SERVER_IP> 'bash /var/www/shikshaportal/deploy/deploy.sh'
```

## Verify

```bash
curl -I https://greenvalley.shikshaportal.in/up
curl https://greenvalley.shikshaportal.in/api/v1/school/current
```

## Production smoke testing (T18)

After deploy, run the smoke script against the live tenant (default: Green Valley demo school):

```bash
bash deploy/smoke-test.sh
```

Configure credentials via environment variables or `deploy/smoke-test.env` (copy from `deploy/smoke-test.env.example`; never commit real passwords):

| Variable | Default | Purpose |
|----------|---------|---------|
| `SMOKE_BASE_URL` | `https://greenvalley.shikshaportal.in` | Tenant base URL |
| `SMOKE_ADMIN_EMAIL` | `principal@greenvalley.test` | School admin login |
| `SMOKE_ADMIN_PASSWORD` | — | Admin password (required in prod) |
| `SMOKE_STUDENT_EMAIL` | `rahul@greenvalley.test` | Student login |
| `SMOKE_STUDENT_PASSWORD` | — | Student password (required in prod) |
| `SMOKE_LOAD_TEST` | `0` | Set to `1` for 50 parallel public API requests |
| `SMOKE_LOAD_COUNT` | `50` | Parallel requests when load test enabled |

From the backend directory:

```bash
SMOKE_BASE_URL=https://greenvalley.shikshaportal.in \
SMOKE_ADMIN_PASSWORD=*** SMOKE_STUDENT_PASSWORD=*** \
bundle exec rails smoke:prod
```

### What the smoke test covers

- Health: `/up`, `/api/v1/health` (includes Redis job queue status)
- Frontend SPA serves `index.html`
- Public school profile and notices
- Admin: login, notices CRUD, AI notice draft, students, attendance, fees, materials
- Student: login (Hindi preference), read notices/attendance/fees/materials, switch to English

The same journey runs in CI via `backend/test/integration/smoke_journey_test.rb` (includes a 50-student login load test).

### Post-deploy (GitHub Actions)

The deploy workflow runs `deploy/smoke-test.sh` after SSH deploy when `SMOKE_ADMIN_PASSWORD` is set. Without that secret, the smoke step is skipped.
