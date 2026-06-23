# Deployment (T03)

## Oracle Cloud VM setup

1. Clone repo to `/var/www/shikshaportal`
2. Configure `backend/.env` with `DATABASE_URL`, `APP_HOST=shikshaportal.in`
3. `cd backend && bundle install && RAILS_ENV=production rails db:prepare`
4. Install Puma systemd service: `sudo cp deploy/puma.service /etc/systemd/system/ && sudo systemctl enable --now puma`
5. Install Nginx: `bash deploy/install-nginx.sh`
6. Cloudflare: see `docs/cloudflare-dns.md`

## Verify

```bash
curl -I https://greenvalley.shikshaportal.in/up
curl https://greenvalley.shikshaportal.in/api/v1/school/current
```
