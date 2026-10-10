# Campixo / Shiksha Portal — Railway production image
# Nginx serves frontend/dist + proxies /api/ and /up to Puma (same as Oracle VM).
#
# Local dev is unchanged — use `rails s` + `npm run dev` as before.
# Build locally: docker build -t campixo .
# Run locally:    docker run -p 8080:8080 --env-file backend/.env campixo

# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.1.6

# --- Frontend build ---
FROM node:20-slim AS frontend
WORKDIR /build/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# --- Backend gem build ---
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS backend-build
WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY backend/ ./
RUN bundle exec bootsnap precompile app/ lib/

# --- Runtime ---
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS runtime

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl gettext-base libjemalloc2 libvips nginx postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    rm -f /etc/nginx/sites-enabled/default

WORKDIR /rails

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

COPY --from=backend-build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=backend-build /rails /rails
COPY --from=frontend /build/frontend/dist /srv/frontend/dist

COPY deploy/nginx-railway.conf /etc/nginx/templates/default.conf.template
COPY deploy/docker-start.sh /docker-start.sh
RUN chmod +x /docker-start.sh && \
    mkdir -p /var/lib/nginx/body /var/log/nginx /run/nginx

EXPOSE 8080
CMD ["/docker-start.sh"]
