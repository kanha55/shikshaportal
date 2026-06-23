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

Copy `.env.example` to `.env` and set `DATABASE_URL` if not using local PostgreSQL defaults.

## Planned (upcoming sprints)

- `acts_as_tenant` multi-tenancy (T02)
- Devise + JWT authentication (T05)
- ActiveStorage → Cloudflare R2
- Sidekiq + Redis
- Rails I18n (`hi` / `en`)
