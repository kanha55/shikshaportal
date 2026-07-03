# frozen_string_literal: true

module Shiksha
  # Central registry of environment variables (T17).
  # Used by env:check and boot-time validation — never stores secret values.
  module Env
    REQUIRED = {
      production: %w[
        DATABASE_URL
        SECRET_KEY_BASE
        JWT_SECRET_KEY
        SUPER_ADMIN_API_KEY
      ],
      staging: %w[
        DATABASE_URL
        SECRET_KEY_BASE
        JWT_SECRET_KEY
        SUPER_ADMIN_API_KEY
      ]
    }.freeze

    OPTIONAL = {
      "APP_HOST" => "Base domain for tenant subdomains (default: campixo.com)",
      "FRONTEND_ORIGIN" => "CORS origin for SPA (production: https://campixo.com)",
      "MAILER_FROM" => "From address for transactional email",
      "JWT_EXPIRY_HOURS" => "JWT lifetime in hours (default: 24)",
      "RAILS_LOG_LEVEL" => "Rails log level (default: info)",
      "RAILS_MAX_THREADS" => "Puma thread count (default: 3)",
      "PORT" => "Puma listen port (default: 3000)",
      "CURSOR_API_KEY" => "Cursor API key for AI Parent Communicator (T15)",
      "CURSOR_AI_MODEL" => "Cursor model id (default: composer-2.5)",
      "ANTHROPIC_API_KEY" => "Fallback AI provider if Cursor key is unset",
      "R2_ACCESS_KEY_ID" => "Cloudflare R2 access key (T10 file uploads)",
      "R2_SECRET_ACCESS_KEY" => "Cloudflare R2 secret key",
      "R2_BUCKET" => "Cloudflare R2 bucket name",
      "R2_ENDPOINT" => "R2 S3-compatible endpoint URL",
      "RESEND_API_KEY" => "Resend API key for production email (future)",
      "SMTP_ADDRESS" => "SMTP host (alternative to Resend)",
      "SMTP_USERNAME" => "SMTP username",
      "SMTP_PASSWORD" => "SMTP password"
    }.freeze

    R2_KEYS = %w[R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_BUCKET R2_ENDPOINT].freeze

    module_function

    def required_for(rails_env)
      REQUIRED.fetch(rails_env.to_sym, [])
    end

    def validate!(rails_env: Rails.env)
      return { ok: true, errors: [], warnings: [] } if rails_env.in?(%w[development test])

      errors = []
      warnings = []

      required_for(rails_env).each do |key|
        errors << "Missing required env var: #{key}" if ENV[key].blank?
      end

      validate_r2_group!(errors)
      validate_dev_secrets!(warnings, rails_env)

      { ok: errors.empty?, errors: errors, warnings: warnings }
    end

    def validate_r2_group!(errors)
      present = R2_KEYS.count { |key| ENV[key].present? }
      return if present.zero?
      return if present == R2_KEYS.size

      errors << "R2 config incomplete — set all of: #{R2_KEYS.join(', ')}"
    end

    def validate_dev_secrets!(warnings, rails_env)
      return unless rails_env.in?(%w[production staging])

      %w[SECRET_KEY_BASE JWT_SECRET_KEY SUPER_ADMIN_API_KEY].each do |key|
        value = ENV[key].to_s
        next if value.blank?

        warnings << "#{key} looks like a dev placeholder — use a strong random value in #{rails_env}" if value.match?(/dev-|change-in-production|password/i)
      end
    end
  end
end
