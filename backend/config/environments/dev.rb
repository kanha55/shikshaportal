# frozen_string_literal: true

# The `dev` environment is a production-like Railway deployment used for
# testing before promoting to production. It reuses the production
# configuration (eager loading, STDOUT logging, host allowlist, and the
# Active Storage service selection) so features like photo uploads behave
# the same as production.
require_relative "production"

Rails.application.configure do
  # Verbose logging on the dev deployment for easier debugging.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")

  # Railway terminates TLS at its edge and forwards plain HTTP to the
  # in-container nginx -> Puma. Forcing SSL here would cause redirect loops,
  # so leave SSL redirects off on the dev deployment.
  config.force_ssl = false
  config.assume_ssl = false
end
