# frozen_string_literal: true

Rails.application.configure do
  config.active_job.queue_adapter = if Rails.env.test?
    :test
  elsif ENV["REDIS_URL"].present?
    :sidekiq
  else
    :async
  end
end
