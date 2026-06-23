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

## Environment

Set in `backend/.env` (production) or shell:

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection |
| `APP_HOST` | Base domain (default `shikshaportal.in`) |
| `SUPER_ADMIN_API_KEY` | Protects `POST /api/v1/admin/schools` |
| `FRONTEND_ORIGIN` | CORS origin for React app |

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

## Planned (upcoming sprints)

- `acts_as_tenant` multi-tenancy (T02)
- Devise + JWT authentication (T05)
- ActiveStorage → Cloudflare R2
- Sidekiq + Redis
- Rails I18n (`hi` / `en`)
