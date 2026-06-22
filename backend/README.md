# Shiksha Portal — Backend (Rails API)

Rails API-only application for Shiksha Portal.

## Planned setup (Sprint 1)

- PostgreSQL with `acts_as_tenant` (school-scoped data)
- Devise + JWT authentication (super_admin, school_admin, student)
- Subdomain-based tenant resolution
- ActiveStorage → Cloudflare R2
- Sidekiq + Redis for async jobs (CSV import, emails, AI)
- Rails I18n (`hi` / `en`) for emails and API errors

## Scaffold command

```bash
rails new . --api --database=postgresql --skip-test
```

See root `README.md` and `docs/shiksha_portal_roadmap.xlsx` for full sprint plan.
