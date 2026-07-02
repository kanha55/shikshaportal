# Deployment (T03 + T16)

## Oracle Cloud VM setup

1. Clone repo to `/var/www/shikshaportal`
2. Configure `backend/.env` with production secrets (see T17 — never commit `.env`)
3. Install Ruby 3.2, Node 20, PostgreSQL client, Bundler
4. `cd backend && bundle install && RAILS_ENV=production rails db:prepare`
5. `cd frontend && npm ci && npm run build`
6. Install Puma systemd service: `sudo cp deploy/puma.service /etc/systemd/system/ && sudo systemctl enable --now puma`
7. Install Nginx: `bash deploy/install-nginx.sh`
8. Cloudflare: see `docs/cloudflare-dns.md`

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
