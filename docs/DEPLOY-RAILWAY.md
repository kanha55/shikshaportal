# Deploy Campixo on Railway

Step-by-step guide to deploy **Shiksha Portal / Campixo** (`campixo.com`) on [Railway](https://railway.com) instead of (or alongside) the Oracle Cloud VM path.

**What you get:** Rails API (Puma) + React SPA (Vite `dist/`) behind Nginx in one Docker container, PostgreSQL, custom domains `campixo.com` + `*.campixo.com`, DNS on Cloudflare.

**Tenant URLs:** `https://greenvalley.campixo.com`, `https://sunrise.campixo.com`, etc.

---

## Before you start (prerequisites)

- [ ] **Domain:** `campixo.com` registered and on **Cloudflare** (nameservers pointed to Cloudflare). See [`docs/D02-D04-cloudflare-campixo.com.md`](D02-D04-cloudflare-campixo.com.md).
- [ ] **GitHub repo:** `kanha55/shikshaportal` (or your fork) with Railway config merged (`Dockerfile`, `railway.toml` at repo root).
- [ ] **Railway account:** Sign up at [railway.com](https://railway.com). Hobby plan ($5/mo) is enough to start.
- [ ] **Secrets ready:** Generate with `cd backend && bundle exec rails secret` (run twice for `JWT_SECRET_KEY`).
- [ ] **Optional external services** (same as Oracle path): Neon or Railway Postgres, Resend email, Cloudflare R2, Anthropic/Cursor API keys.

### Architecture (Railway path)

```
Browser → Cloudflare (SSL) → Railway custom domain
         → Nginx :PORT (SPA + /api/ proxy) → Puma :3000 → PostgreSQL
```

This mirrors the Oracle VM layout in [`docs/nginx-wildcard.conf`](nginx-wildcard.conf), packaged in the root [`Dockerfile`](../Dockerfile).

---

## Phase 1 — Railway account + project from GitHub

1. Log in to [Railway Dashboard](https://railway.com/dashboard).
2. Click **New Project** → **Deploy from GitHub repo**.
3. Authorize Railway for GitHub if prompted; select **`shikshaportal`**.
4. Railway creates a service from the repo. Rename it to **`campixo-web`** (Settings → name).
5. **Root directory:** leave as **repo root** (`/`), **not** `backend/`. The root `Dockerfile` builds frontend + backend together.
6. Confirm **`railway.toml`** is detected (Settings → Build → should show Dockerfile builder).
7. Do **not** deploy successfully yet — add the database and env vars first (Phases 2–3).

- [ ] Railway project created
- [ ] GitHub repo connected
- [ ] Service root = repo root
- [ ] `railway.toml` / `Dockerfile` recognized

---

## Phase 2 — PostgreSQL database

You need a `DATABASE_URL` for production. Two supported options:

### Option A — Railway PostgreSQL (simplest)

1. In the project canvas, click **+ New** → **Database** → **PostgreSQL**.
2. Railway provisions Postgres and exposes `DATABASE_URL` on the database service.
3. On **`campixo-web`**, add a **variable reference**:
   - Variable name: `DATABASE_URL`
   - Value: `${{Postgres.DATABASE_URL}}` (use the **Reference** tab; pick your Postgres service).
4. Railway private networking resolves this automatically inside the project.

### Option B — Neon free tier (existing D12 path)

1. Create a project at [neon.tech](https://neon.tech) (free tier is fine for pilot).
2. Copy the **pooled** connection string (`postgres://…?sslmode=require`).
3. On **`campixo-web`**, set `DATABASE_URL` to that string manually.
4. Keep Neon backup branch setup (D30) on Neon’s dashboard.

| | Railway Postgres | Neon |
|---|------------------|------|
| Setup | One click in project | External dashboard |
| Cost | Uses Railway usage credits | Free tier → paid as you grow |
| Good for | All-in-one Railway | Already using Neon (D12) |

- [ ] `DATABASE_URL` set on `campixo-web`
- [ ] DB reachable (deploy logs show `db:prepare` success)

---

## Phase 3 — Backend / web service environment variables

Set these on **`campixo-web`** → **Variables** (Railway dashboard or `railway variables` CLI).

### Required

| Variable | Example / notes |
|----------|-----------------|
| `RAILS_ENV` | `production` |
| `APP_HOST` | `campixo.com` |
| `DATABASE_URL` | From Phase 2 |
| `SECRET_KEY_BASE` | `rails secret` output |
| `JWT_SECRET_KEY` | Different `rails secret` output |
| `SUPER_ADMIN_API_KEY` | Long random string |
| `FRONTEND_ORIGIN` | `https://campixo.com` (CORS) |

### Recommended

| Variable | Example / notes |
|----------|-----------------|
| `MAILER_FROM` | `noreply@campixo.com` |
| `RAILS_LOG_LEVEL` | `info` |
| `RAILS_MAX_THREADS` | `3` |

### Optional (feature flags)

| Variable | Purpose |
|----------|---------|
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_ENDPOINT` | Cloudflare R2 uploads (all four required together) |
| `RESEND_API_KEY` or `SMTP_*` | Transactional email |
| `CURSOR_API_KEY` / `ANTHROPIC_API_KEY` | AI Parent Communicator |
| `RAILS_MASTER_KEY` | Only if you use encrypted credentials (`config/credentials`) |

Validate locally against the same keys:

```bash
cd backend
RAILS_ENV=production DATABASE_URL=... bin/check-env
```

### Build & start commands

**No manual build/start needed** when using the root `Dockerfile`:

| Step | What happens |
|------|----------------|
| **Build** | Docker multi-stage: `npm ci && npm run build` (frontend) + `bundle install` (backend) |
| **Start** | `deploy/docker-start.sh` → `rails db:prepare` → Puma `:3000` + Nginx on Railway `PORT` |
| **Health check** | `GET /up` (configured in `railway.toml`) |

If you ever switch to **Nixpacks** (not recommended for this app), you would need custom build/start — stick with the Dockerfile path.

- [ ] All required env vars set
- [ ] `bin/check-env` passes with production values

---

## Phase 4 — Frontend serving options

Campixo needs the React SPA **and** `/api/` on the **same hostname** per tenant (`greenvalley.campixo.com`). That rules out “API on Railway + SPA on a different host” without extra routing.

### Option A — Combined Docker (recommended) ✅

Use the repo root **`Dockerfile`** (already configured):

- Nginx serves `frontend/dist/` and proxies `/api/` + `/up` to Puma.
- One Railway service, one deploy, wildcard-friendly.
- Config: [`deploy/nginx-railway.conf`](../deploy/nginx-railway.conf).

### Option B — Separate static service (advanced, not recommended)

| Piece | Service | Notes |
|-------|---------|-------|
| API | Railway `campixo-api` | Puma only, `backend/Dockerfile` |
| SPA | Railway static or Cloudflare Pages | Must rewrite `/api/*` to API — complex for `*.campixo.com` |

Only consider Option B if you add Cloudflare Workers or a reverse proxy in front of both. For Hobby plan + multi-tenant subdomains, **use Option A**.

- [ ] Using combined Docker (Option A)
- [ ] First deploy builds without frontend/API URL errors

---

## Phase 5 — Custom domains on Railway

Railway **Hobby plan:** **2 custom domains per service**. Use them for:

1. **`campixo.com`** (apex / marketing / redirects)
2. **`*.campixo.com`** (wildcard — all school tenants)

Do **not** add `www.campixo.com` as a third Railway domain on Hobby — use a Cloudflare redirect (Phase 6).

### Add apex domain

1. **`campixo-web`** → **Settings** → **Networking** → **+ Custom Domain**.
2. Enter **`campixo.com`**.
3. Railway shows a **CNAME target** (e.g. `xxxx.up.railway.app`) and a **TXT** record for ownership verification.
4. Copy both — you will add them in Cloudflare (Phase 6).
5. Set **target port** to match what Nginx listens on (Railway auto-detects from `PORT`; default after deploy is fine).

### Add wildcard domain

1. **+ Custom Domain** again → enter **`*.campixo.com`**.
2. Railway shows **three** DNS records:
   - CNAME for `*.campixo.com` → Railway target
   - CNAME for `_acme-challenge` (SSL certificate)
   - TXT for domain ownership verification
3. Wildcard **will not verify** without **all three** records.

Wait until Railway shows a **green checkmark** next to each domain (can take minutes to an hour; up to 72h DNS propagation worldwide).

- [ ] `campixo.com` added in Railway
- [ ] `*.campixo.com` added in Railway
- [ ] Both show verified (green check)

---

## Phase 6 — Cloudflare DNS

Assuming `campixo.com` uses Cloudflare nameservers (D02–D04).

### Records for Railway

Add the records Railway gives you. Typical layout:

| Type | Name | Target / Content | Proxy |
|------|------|------------------|-------|
| CNAME | `@` | `<railway-cname>.up.railway.app` | **Proxied** (orange cloud) ✅ |
| TXT | `_railway-verify` (or as shown) | `<verification string>` | DNS only |
| CNAME | `*` | `<railway-wildcard-cname>` | **Proxied** ✅ |
| CNAME | `_acme-challenge` | `<railway-acme-target>` | **DNS only** (grey cloud) ⚠️ |
| TXT | (wildcard verify) | `<verification string>` | DNS only |

### Grey cloud vs orange cloud

| Record | Cloudflare proxy | Why |
|--------|------------------|-----|
| `@`, `*` (app traffic) | **Orange** (Proxied) | DDoS protection, CDN; Railway docs allow this with SSL **Full** |
| `_acme-challenge`, ownership TXT | **Grey** (DNS only) | Required so Railway can issue SSL for wildcard |
| `_railway-verify` TXT | **Grey** | Ownership verification |

### Cloudflare SSL settings (required)

1. **SSL/TLS** → **Overview** → mode **Full** (not Full Strict — Railway origin cert differs).
2. **SSL/TLS** → **Edge Certificates** → **Universal SSL** enabled.
3. Railway dashboard may show **“Cloudflare proxy detected”** with a green cloud — expected.

### Remove old Oracle DNS (when switching)

If migrating from Oracle VM, **delete** the old wildcard **A** record (`*` → VM IP) from [`docs/D02-D04-cloudflare-campixo.com.md`](D02-D04-cloudflare-campixo.com.md). Replace with Railway CNAMEs above.

### `www` redirect (saves a Railway domain slot)

Use Cloudflare **Bulk Redirects** or a Page Rule: `https://www.campixo.com/*` → `https://campixo.com/$1` (301).

- [ ] Apex CNAME → Railway (proxied)
- [ ] Wildcard CNAME → Railway (proxied)
- [ ] `_acme-challenge` grey cloud
- [ ] TXT verification records added
- [ ] SSL mode = Full
- [ ] Old Oracle A records removed (if migrating)

---

## Phase 7 — Migrations, seeds, smoke test

### First deploy

1. Trigger deploy: **Deploy** button or push to connected branch.
2. Watch logs for:
   - `Preparing database...`
   - `Starting Puma on port 3000`
   - `Starting Nginx on port …`
3. `db:prepare` runs automatically on each container start (`deploy/docker-start.sh`).

### Seed demo schools (once)

Railway **one-off command** (Settings → Deploy → run command, or CLI):

```bash
bundle exec rails db:seed
```

This creates **Green Valley** and **Sunrise** demo tenants (see `backend/db/seeds.rb`). Change default passwords before real pilot.

### Create super admin (production)

Prefer a dedicated admin user over seed defaults:

```bash
bundle exec rails console
# SuperAdmin.create!(...) or follow your onboarding runbook
```

### Smoke test

From your laptop:

```bash
curl -sf https://greenvalley.campixo.com/up
curl -sf https://greenvalley.campixo.com/api/v1/health
```

Full journey:

```bash
SMOKE_BASE_URL=https://greenvalley.campixo.com \
SMOKE_ADMIN_PASSWORD=your-prod-password \
SMOKE_STUDENT_PASSWORD=your-prod-password \
bash deploy/smoke-test.sh
```

Or from Railway/local with env:

```bash
cd backend && bundle exec rails smoke:prod
```

- [ ] Deploy succeeded
- [ ] `https://greenvalley.campixo.com/up` returns 200
- [ ] Login works on tenant subdomain
- [ ] Smoke test passes

---

## Phase 8 — GitHub deploy workflow

### Railway native deploy (recommended for Railway path)

Railway auto-deploys when you push to the connected branch (usually `main`):

1. **Settings** → **Source** → branch `main` (or `production`).
2. Enable **Wait for CI** if you connect GitHub checks (optional).
3. Each merge to `main` → Railway rebuilds Docker image → rolling deploy.

No SSH secrets required. Remove dependency on Oracle VM for day-to-day deploys.

### Oracle `deploy.yml` (legacy path)

[`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml) still SSHs to Oracle Cloud after CI. When Railway is primary:

| Action | When |
|--------|------|
| **Keep** | During parallel run / rollback window |
| **Disable** | Delete or `if: false` job when Railway is stable |
| **Replace smoke step** | Run smoke against Railway URL in CI (optional separate workflow) |

Suggested: add a GitHub **Environment** `railway-production` for manual approval on first go-live, then rely on Railway auto-deploy.

- [ ] Railway connected to `main` branch
- [ ] Test push triggers deploy
- [ ] Oracle workflow disabled or marked legacy (when ready)

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Custom domain **404** on Railway | Missing **TXT** verification record | Add TXT exactly as Railway shows; wait for green check |
| Wildcard SSL stuck | `_acme-challenge` proxied (orange) | Set **DNS only** (grey cloud) |
| `ERR_TOO_MANY_REDIRECTS` | Cloudflare SSL = Full Strict | Set SSL to **Full** |
| API calls fail, SPA loads | Frontend hitting `:3000` | Fixed in prod via `frontend/src/lib/config.ts` (same-origin `/api/v1`); redeploy |
| `502` / health check fail | Container crash, DB down | Check deploy logs; verify `DATABASE_URL` |
| Tenant not found | Wrong subdomain / `APP_HOST` | Ensure `APP_HOST=campixo.com` and school exists in DB |
| CORS errors | `FRONTEND_ORIGIN` mismatch | Set to `https://campixo.com` or tenant URL pattern your app expects |
| Build OOM | Frontend + Ruby build in one Dockerfile | Retry deploy; upgrade plan or enable larger build resources |
| Old Oracle IP still served | Stale Cloudflare A record | Remove `*` A record; use Railway CNAME |

**Railway CLI useful commands:**

```bash
npm i -g @railway/cli
railway login
railway link
railway logs
railway run bundle exec rails db:seed
railway domain campixo.com
railway domain '*.campixo.com'
```

**Docs:** [Railway custom domains](https://docs.railway.com/networking/domains/working-with-domains) · [Pricing](https://docs.railway.com/pricing/plans)

---

## Cost estimate (Hobby plan, 2025/2026)

| Item | Typical monthly cost |
|------|----------------------|
| Hobby subscription | **$5/mo** (includes **$5 usage credit**) |
| Web service (512MB–1GB RAM, always on) | ~$3–8 usage |
| Railway PostgreSQL (small) | ~$2–5 usage |
| Neon (if Option B) | $0 free tier → ~$19+ at scale |
| Cloudflare DNS + proxy | $0 on free plan |
| **Total (Railway + DB)** | **~$5–15/mo** if usage stays modest |

Usage is billed per second (CPU, RAM, egress). A quiet pilot school portal often lands near **$5–10/mo** total on Hobby; heavy traffic or large DB pushes toward **$15+**. Monitor **Project → Usage** in Railway.

---

## Go-live checklist

Copy this block into your issue tracker:

```
Railway Campixo go-live
- [ ] Phase 1: Railway project + GitHub connected
- [ ] Phase 2: DATABASE_URL (Railway Postgres or Neon)
- [ ] Phase 3: Production env vars + check-env
- [ ] Phase 4: Combined Docker deploy green
- [ ] Phase 5: campixo.com + *.campixo.com verified on Railway
- [ ] Phase 6: Cloudflare CNAME/TXT + SSL Full + acme grey cloud
- [ ] Phase 7: db:seed / super admin + smoke test pass
- [ ] Phase 8: Auto-deploy from main; Oracle workflow retired
- [ ] D22: UptimeRobot on https://greenvalley.campixo.com/up
- [ ] Pilot: register real school, change demo passwords
```

---

## Related docs

| Doc | Purpose |
|-----|---------|
| [`docs/DEPLOYMENT_TASKS.md`](DEPLOYMENT_TASKS.md) | Full D01–D32 checklist (Oracle + Railway columns) |
| [`docs/D02-D04-cloudflare-campixo.com.md`](D02-D04-cloudflare-campixo.com.md) | Cloudflare domain setup |
| [`deploy/README.md`](../deploy/README.md) | Oracle VM runbook (legacy) |
| [`deploy/smoke-test.sh`](../deploy/smoke-test.sh) | Post-deploy verification |
| [`Dockerfile`](../Dockerfile) | Production image |
| [`railway.toml`](../railway.toml) | Railway build/deploy settings |
