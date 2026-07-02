# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173"),
      /\Ahttps?:\/\/[\w-]+\.shikshaportal\.in\z/,
      /\Ahttp:\/\/[\w-]+\.localhost(:\d+)?\z/
    )

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true,
      expose: %w[Authorization Content-Type Content-Disposition]
  end

  allow do
    origins "*"
    resource "/up", headers: :any, methods: %i[get]
  end
end
