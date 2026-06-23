# Shiksha Portal — Frontend (React)

Vite + React + TypeScript SPA with JWT auth (T06).

## Setup

```bash
cd frontend
npm install
npm run dev
```

Open `http://greenvalley.localhost:5173/login` (map `*.localhost` in `/etc/hosts` or use localhost for super admin).

## Auth flow

- JWT stored **in memory only** (React ref — not localStorage)
- Login → role-based redirect: `/super-admin`, `/admin`, `/student`
- API base URL follows current subdomain: `{hostname}:3000/api/v1`

## Environment

| Variable | Description |
|----------|-------------|
| `VITE_API_URL` | Override API base (optional) |

## Dev login (seed data)

| Email | Password | Role |
|-------|----------|------|
| `super@shikshaportal.test` | `password123` | super_admin |
| `principal@greenvalley.test` | `password123` | school_admin |

Run backend on port 3000: `cd backend && rails s`
