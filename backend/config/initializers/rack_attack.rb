# frozen_string_literal: true

LOGIN_ATTEMPT_LIMIT = 10
LOGIN_ATTEMPT_PERIOD = 15.minutes

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

class Rack::Attack
  throttle("auth/login/ip", limit: LOGIN_ATTEMPT_LIMIT, period: LOGIN_ATTEMPT_PERIOD) do |req|
    req.ip if req.post? && req.path == "/api/v1/auth/login"
  end

  throttle("auth/login/email", limit: LOGIN_ATTEMPT_LIMIT, period: LOGIN_ATTEMPT_PERIOD) do |req|
    if req.post? && req.path == "/api/v1/auth/login"
      req.params.dig("user", "email")&.downcase.presence
    end
  end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: I18n.t("errors.too_many_login_attempts", default: "Too many login attempts. Try again later.") }.to_json]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack

# Rate limiting is validated in AuthIntegrationTest; disable elsewhere so login
# helpers in integration tests are not throttled by a shared IP counter.
Rack::Attack.enabled = false if Rails.env.test?
