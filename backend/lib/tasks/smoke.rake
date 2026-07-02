# frozen_string_literal: true

namespace :smoke do
  desc "Run deploy/smoke-test.sh against production (set SMOKE_BASE_URL and credentials)"
  task :prod do
    script = Rails.root.join("../deploy/smoke-test.sh").expand_path
    abort "Smoke script not found: #{script}" unless script.exist?

    env = ENV.to_h
    success = system(env, "bash", script.to_s)
    abort "Production smoke test failed" unless success
  end
end
