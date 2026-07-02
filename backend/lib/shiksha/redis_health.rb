# frozen_string_literal: true

module Shiksha
  module RedisHealth
    module_function

    def check
      return { status: "skipped", message: "REDIS_URL not configured" } if ENV["REDIS_URL"].blank?

      Sidekiq.redis { |conn| conn.ping }
      { status: "ok" }
    rescue StandardError => e
      { status: "error", message: e.message }
    end
  end
end
