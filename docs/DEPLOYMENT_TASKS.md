# Deployment checklist (D01–D32)

Operational steps from the **🚀 Deployment** sheet in `shiksha_portal_roadmap.xlsx`. Sprint tasks T01–T23 cover application code and repo automation; this checklist tracks **production infrastructure and go-live** work.

**Domain:** **campixo.com** — tenant URLs like `greenvalley.campixo.com`.

**Deploy paths:** **Oracle Cloud VM** (original, D05–D11) **or** **Railway** (alternative — see [`docs/DEPLOY-RAILWAY.md`](DEPLOY-RAILWAY.md)). Steps D12+ (database, env, smoke, go-live) apply to both paths unless noted.

**Legend:** ✅ Done (covered by merged sprint / repo) · 🟡 Partial (code or docs exist; prod step may remain) · ☐ Todo

| ID | Phase | Step | Service | Status | Sprint / notes |
|----|-------|------|---------|--------|----------------|
| D01 | 1 — Domain & DNS | Purchase domain | GoDaddy | ✅ | **campixo.com** purchased |
| D02 | 1 | Add domain to Cloudflare | Cloudflare | ☐ | See [`docs/D02-D04-cloudflare-campixo.com.md`](D02-D04-cloudflare-campixo.com.md) |
| D03 | 1 | Add wildcard A record (`*` → Oracle VM IP) | Cloudflare DNS | 🟡 | D02-D04 guide — config documented |
| D04 | 1 | Enable wildcard SSL (Full strict) | Cloudflare SSL | 🟡 | D02-D04 guide — no Certbot on server |
| D05 | 2 — Server | Create Oracle Cloud account | Oracle Cloud | ☐ | **Or Railway:** [`docs/DEPLOY-RAILWAY.md`](DEPLOY-RAILWAY.md) Phase 1 — skip D05–D11 |
| D06 | 2 | Create Always Free VM (Ampere ARM) | Oracle Cloud | ☐ | Railway path: not needed |
| D07 | 2 | SSH into server | Terminal | ☐ | Railway path: not needed |
| D08 | 2 | Install Ruby + Rails stack | Oracle VM | 🟡 | Oracle: `deploy/README.md` · Railway: root `Dockerfile` |
| D09 | 2 | Install Node.js 20 | Oracle VM | 🟡 | Oracle: `deploy/deploy.sh` · Railway: Docker frontend stage |
| D10 | 2 | Install Nginx + Puma systemd | Oracle VM | 🟡 | Oracle: T03 — `deploy/puma.service` · Railway: `deploy/docker-start.sh` |
| D11 | 2 | Configure Nginx wildcard `*.campixo.com` | Oracle VM | 🟡 | Oracle: `docs/nginx-wildcard.conf` · Railway: `deploy/nginx-railway.conf` + Phase 5–6 |
| D12 | 3 — DB & storage | Create Neon.tech project + `DATABASE_URL` | Neon | 🟡 | T17 — `.env.example` |
| D13 | 3 | Create Cloudflare R2 bucket | R2 | 🟡 | T10 — R2 env vars in T17 |
| D14 | 3 | Create Resend account + verify domain | Resend | 🟡 | T04/T08 emails |
| D15 | 3 | Get Claude / Anthropic API key | Anthropic | 🟡 | T15 AI notices |
| D16 | 4 — App config | Set production env vars on VM | Oracle VM | 🟡 | T17 — `backend/.env.example`, `bin/check-env` · Railway: Phase 3 in DEPLOY-RAILWAY |
| D17 | 4 | Run DB migrations on production | Oracle VM | 🟡 | Oracle: `deploy/deploy.sh` · Railway: auto `db:prepare` on start |
| D18 | 4 | Build React frontend for production | Oracle VM | 🟡 | Oracle: `deploy/deploy.sh` · Railway: Docker build stage |
| D19 | 4 | Create super admin account | Rails console | 🟡 | `db/seeds.rb` — confirm prod user |
| D20 | 5 — CI/CD | GitHub Actions deploy workflow | GitHub | ✅ | T16 — `.github/workflows/deploy.yml` (Oracle SSH) · Railway: native GitHub deploy — DEPLOY-RAILWAY Phase 8 |
| D21 | 5 | Add deploy secrets to GitHub | GitHub | 🟡 | T16 — `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY` |
| D22 | 5 | Setup UptimeRobot monitor | UptimeRobot | ☐ | Alert on `campixo.com/up` |
| D23 | 5 | Test full deployment pipeline | GitHub Actions | 🟡 | T16/T18 — push to `main`, verify live site |
| D24 | 6 — Go live | Register first test school on prod | App | 🟡 | T18 smoke — manual super-admin flow |
| D25 | 6 | Add students + mark attendance | App | 🟡 | T18 smoke script |
| D26 | 6 | Test AI Parent Communicator on prod | App | 🟡 | T18 smoke script |
| D27 | 6 | Mobile responsiveness test | Browser | ☐ | Real device pass beyond automated smoke |
| D28 | 6 | Share with first real school (pilot) | Real world | ☐ | On-site demo + onboarding |
| D29 | 6 | Install Redis + Sidekiq on VM | Oracle VM | ☐ | T23 ([#23](https://github.com/kanha55/shikshaportal/issues/23)) — `deploy/sidekiq.service` |
| D30 | 6 | Setup Neon DB backup branch | Neon | ☐ | Weekly branch + restore runbook |
| D31 | 6 | Noto Sans Devanagari on prod | Google Fonts | ✅ | T20 — frontend font wired |
| D32 | 6 | Hindi ↔ English toggle on prod | Browser | 🟡 | T21 — verify on live tenant |

## GitHub deployment issues

Grouped issues for remaining operational work (sprint T01–T22 merged; T23/D29 tracked separately):

| Issue | Scope | IDs |
|-------|--------|-----|
| [#43](https://github.com/kanha55/shikshaportal/issues/43) | Domain, DNS & Oracle VM **or Railway** | D01–D11 |
| [#44](https://github.com/kanha55/shikshaportal/issues/44) | External services & prod bootstrap | D12–D19 |
| [#45](https://github.com/kanha55/shikshaportal/issues/45) | Monitoring, backups & pipeline verify | D22, D23, D30 |
| [#46](https://github.com/kanha55/shikshaportal/issues/46) | Go-live pilot & manual QA | D24–D28, D31–D32 |
| [#23](https://github.com/kanha55/shikshaportal/issues/23) | Redis + Sidekiq (T23) | D29 |

### Railway alternative (D05–D11)

Skip Oracle VM provisioning when using Railway. Follow [`docs/DEPLOY-RAILWAY.md`](DEPLOY-RAILWAY.md) Phases 1–8 instead of D05–D11. Reuse D02–D04 Cloudflare steps with Railway CNAME targets (Phase 6).

## Quick links

- **Railway deploy:** [`docs/DEPLOY-RAILWAY.md`](DEPLOY-RAILWAY.md)
- Cloudflare D02–D04: [`docs/D02-D04-cloudflare-campixo.com.md`](D02-D04-cloudflare-campixo.com.md)
- Deploy runbook: [`deploy/README.md`](../deploy/README.md)
- Cloudflare DNS (quick): [`docs/cloudflare-dns.md`](cloudflare-dns.md)
- Post-deploy smoke: [`deploy/smoke-test.sh`](../deploy/smoke-test.sh)
