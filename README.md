# Shiksha Portal

Village school and college education platform — multi-tenant, Hindi + English, low-cost MVP.

## Overview

Shiksha Portal helps schools manage students, notices, study materials, attendance, and fees. Each school gets its own subdomain (e.g. `greenvalley.shikshaportal.in`).

**Key features (MVP roadmap):**

- Multi-tenant school onboarding with subdomain routing
- Authentication for super admin, school admin, and students
- Bilingual UI (Hindi + English) with `react-i18next`
- AI Parent Communicator — formal notice + WhatsApp message from rough Hindi/English input
- Notice board, study materials (PDF on Cloudflare R2), attendance, fee records
- Student and admin dashboards

## Tech stack

| Layer | Technology |
|-------|------------|
| Backend | Ruby on Rails 7 (API-only), PostgreSQL |
| Frontend | React, Tailwind CSS, react-i18next |
| Auth | Devise + JWT |
| Multi-tenancy | acts_as_tenant |
| Storage | Cloudflare R2 (ActiveStorage) |
| Email | Resend |
| AI | Claude Haiku API |
| Jobs | Sidekiq + Redis |
| Hosting | Oracle Cloud (Always Free), Neon.tech, Cloudflare |

## Repository structure

```
shikshaportal/
├── backend/          # Rails API
├── frontend/         # React SPA
├── docs/             # Product roadmap and architecture notes
└── .github/workflows # CI/CD
```

## Getting started

> Backend and frontend apps will be scaffolded in Sprint 1 (see `docs/` roadmap).

### Prerequisites

- Ruby 3.2+
- Node.js 20+
- PostgreSQL (or Neon.tech URL for production)

### Development (coming soon)

```bash
# Backend
cd backend && bundle install && rails db:setup && rails s

# Frontend
cd frontend && npm install && npm run dev
```

## Deployment

Production target: Oracle Cloud VM + Neon PostgreSQL + Cloudflare (DNS, SSL, R2). See `docs/` and `.github/workflows/deploy.yml`.

## License

Private — all rights reserved until open-source license is chosen.
