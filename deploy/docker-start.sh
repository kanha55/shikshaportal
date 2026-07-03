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

echo "==> Waiting for Puma /up..."
for i in $(seq 1 60); do
  if curl -sf http://127.0.0.1:3000/up > /dev/null; then
    echo "==> Puma is ready."
    break
  fi
  if ! kill -0 "$PUMA_PID" 2>/dev/null; then
    echo "ERROR: Puma exited during startup. Check logs above for missing env vars or DB errors." >&2
    exit 1
  fi
  if [ "$i" -eq 60 ]; then
    echo "ERROR: Puma did not respond on /up within 60s." >&2
    exit 1
  fi
  sleep 1
done

export PORT="${PORT:-8080}"
echo "==> Starting Nginx on port ${PORT}..."
mkdir -p /etc/nginx/sites-enabled
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/sites-enabled/default

nginx -t
exec nginx -g 'daemon off;'
