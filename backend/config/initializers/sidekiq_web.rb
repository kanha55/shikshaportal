# frozen_string_literal: true

require "sidekiq/web"

if ENV["SIDEKIQ_WEB_PASSWORD"].present?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("SIDEKIQ_WEB_USER", "admin")) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_WEB_PASSWORD"])
  end
end
