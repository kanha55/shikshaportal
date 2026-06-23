#!/usr/bin/env bash
# T03 — Install Nginx wildcard config on Oracle Cloud VM (Ubuntu)
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/shikshaportal}"
NGINX_SITE="/etc/nginx/sites-available/shikshaportal"

sudo apt-get update
sudo apt-get install -y nginx

sudo cp "$APP_ROOT/docs/nginx-wildcard.conf" "$NGINX_SITE"
sudo ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/shikshaportal
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "Nginx wildcard config installed. Point Cloudflare * A record to this server IP."
