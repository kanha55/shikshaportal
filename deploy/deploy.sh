#!/usr/bin/env bash
# T16 — Production deploy script (runs on Oracle Cloud VM via GitHub Actions SSH)
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/shikshaportal}"

cd "$APP_ROOT"

echo "==> Pulling latest main..."
git fetch origin main
git reset --hard origin/main

echo "==> Validating environment..."
cd backend
RAILS_ENV=production bin/check-env

echo "==> Installing backend gems..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

echo "==> Running migrations..."
RAILS_ENV=production bundle exec rails db:migrate

echo "==> Building frontend..."
cd ../frontend
npm ci
npm run build

echo "==> Restarting Puma..."
sudo systemctl restart puma

echo "==> Reloading Nginx..."
sudo nginx -t
sudo systemctl reload nginx

echo "==> Health check..."
sleep 3
curl -sf http://127.0.0.1:3000/up
echo

if [[ "${RUN_SMOKE_TEST:-0}" == "1" && -f "${APP_ROOT}/deploy/smoke-test.sh" ]]; then
  echo "==> Running production smoke test..."
  SMOKE_BASE_URL="${SMOKE_BASE_URL:-https://greenvalley.campixo.com}" \
    bash "${APP_ROOT}/deploy/smoke-test.sh"
fi

echo "Deploy complete."
