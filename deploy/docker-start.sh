#!/usr/bin/env bash
# Start Puma (internal :3000) + Nginx (Railway PORT) for production container.
set -euo pipefail

if [ -z "${LD_PRELOAD+x}" ] && compgen -G "/usr/lib/*/libjemalloc.so.2" > /dev/null; then
  export LD_PRELOAD="$(echo /usr/lib/*/libjemalloc.so.2)"
fi

cd /rails

echo "==> Preparing database..."
bundle exec rails db:prepare

echo "==> Starting Puma on port 3000..."
PORT=3000 bundle exec puma -C config/puma.rb &
PUMA_PID=$!

cleanup() {
  kill "$PUMA_PID" 2>/dev/null || true
}
trap cleanup EXIT

export PORT="${PORT:-8080}"
echo "==> Starting Nginx on port ${PORT}..."
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/sites-enabled/default

nginx -t
exec nginx -g 'daemon off;'
