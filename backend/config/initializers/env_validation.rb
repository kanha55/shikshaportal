# frozen_string_literal: true

# Fail fast in production/staging when required secrets are missing (T17).
if Rails.env.production? || Rails.env.staging?
  result = Shiksha::Env.validate!

  result[:warnings].each do |message|
    Rails.logger.warn("[env] #{message}")
  end

  unless result[:ok]
    raise <<~MSG
      Environment configuration invalid:
      #{result[:errors].map { |e| "  - #{e}" }.join("\n")}

      Copy backend/.env.example to backend/.env and set production values.
      Run `bin/rails env:check` for details.
    MSG
  end
end
