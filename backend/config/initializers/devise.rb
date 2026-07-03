# frozen_string_literal: true

Devise.setup do |config|
  config.parent_controller = "ApplicationController"
  config.mailer_sender = ENV.fetch("MAILER_FROM", "noreply@campixo.com")
  config.mailer = "DeviseMailer"

  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth, :params_auth]
  config.navigational_formats = []
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.paranoid = true
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.sign_in_after_reset_password = false

  config.jwt do |jwt|
    jwt.secret = ENV.fetch("JWT_SECRET_KEY") { Rails.application.secret_key_base.to_s }
    jwt.expiration_time = ENV.fetch("JWT_EXPIRY_HOURS", "24").to_i.hours.to_i
    jwt.dispatch_requests = [
      ["POST", %r{^/api/v1/auth/login$}]
    ]
    jwt.revocation_requests = [
      ["DELETE", %r{^/api/v1/auth/logout$}]
    ]
  end
end
