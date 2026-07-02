require_relative "production"

Rails.application.configure do
  # Staging mirrors production with a separate DB and slightly verbose logging.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")
end
