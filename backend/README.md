# Shiksha Portal — Backend (Rails API)

Rails 7.2 API-only application for Shiksha Portal.

## Setup

```bash
cd backend
bundle install
rails db:create db:migrate
rails server -p 3000
```

## Health checks

- `GET /up` — Rails health check
- `GET /api/v1/health` — API JSON health response

## Environment (T17)

Copy the template and edit locally — **never commit `.env`**:

```bash
cp .env.example .env
bin/check-env   # validates in production/staging only
```

| Variable | Required | Purpose |
|----------|----------|---------|
| `DATABASE_URL` | prod/staging | PostgreSQL connection |
| `SECRET_KEY_BASE` | prod/staging | Rails session/crypto |
| `JWT_SECRET_KEY` | prod/staging | JWT signing (use `rails secret`) |
| `SUPER_ADMIN_API_KEY` | prod/staging | Protects `POST /api/v1/admin/schools` |
| `APP_HOST` | — | Base domain (default `shikshaportal.in`) |
| `FRONTEND_ORIGIN` | — | CORS origin for React app |
| `MAILER_FROM` | — | Transactional email from address |
| `CURSOR_API_KEY` | — | Cursor API for AI Parent Communicator (T15) |
| `CURSOR_AI_MODEL` | — | Optional Cursor model id (default `composer-2.5`) |
| `ANTHROPIC_API_KEY` | — | Fallback AI provider if Cursor key is not set |
| `R2_ACCESS_KEY_ID` | — | Cloudflare R2 (set all four `R2_*` together) |
| `R2_SECRET_ACCESS_KEY` | — | R2 secret key |
| `R2_BUCKET` | — | R2 bucket name |
| `R2_ENDPOINT` | — | R2 S3 endpoint URL |

Staging uses a separate template: `cp .env.staging.example .env` with `RAILS_ENV=staging`.
See `deploy/README.md` for production server setup.

## Super admin — register a school (T04)

```bash
curl -X POST http://localhost:3000/api/v1/admin/schools \
  -H "Content-Type: application/json" \
  -H "X-Super-Admin-Key: $SUPER_ADMIN_API_KEY" \
  -d '{
    "school": {
      "name": "Demo School",
      "subdomain": "demo",
      "address": "Village Road",
      "phone": "9999999999",
      "principal_name": "Principal Singh",
      "principal_email": "admin@demo.test",
      "board": "cbse",
      "default_language": "hi"
    }
  }'
```

Creates school tenant, school admin user, and sends welcome email.

## Authentication (T05)

JWT is returned in the `Authorization` response header on login.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/auth/login` | — | Login (`user[email]`, `user[password]`) |
| DELETE | `/api/v1/auth/logout` | JWT | Logout / revoke token |
| GET | `/api/v1/auth/me` | JWT | Current user profile + role |
| POST | `/api/v1/auth/password` | — | Request password reset email |
| PUT | `/api/v1/auth/password` | — | Reset password with token |

### Login example

```bash
curl -i -X POST http://greenvalley.localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"principal@greenvalley.test","password":"password123"}}'
```

Use the `Authorization: Bearer <token>` header for protected routes.

Seed users: `super@shikshaportal.test`, `principal@greenvalley.test` (password: `password123`).

## Planned (upcoming sprints)

- `acts_as_tenant` multi-tenancy (T02)
- Devise + JWT authentication (T05)
- ActiveStorage → Cloudflare R2
- Sidekiq + Redis
- Rails I18n (`hi` / `en`)
