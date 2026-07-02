# frozen_string_literal: true

require "test_helper"

class ShikshaEnvTest < ActiveSupport::TestCase
  test "validate passes in test environment without required vars" do
    result = Shiksha::Env.validate!(rails_env: "test")
    assert result[:ok]
    assert_empty result[:errors]
  end

  test "validate requires core secrets in production" do
    with_env(
      "DATABASE_URL" => nil,
      "SECRET_KEY_BASE" => nil,
      "JWT_SECRET_KEY" => nil,
      "SUPER_ADMIN_API_KEY" => nil
    ) do
      result = Shiksha::Env.validate!(rails_env: "production")
      refute result[:ok]
      assert_includes result[:errors].join, "DATABASE_URL"
      assert_includes result[:errors].join, "SECRET_KEY_BASE"
    end
  end

  test "validate passes production when all required vars set" do
    with_env(
      "DATABASE_URL" => "postgres://localhost/shikshaportal_production",
      "SECRET_KEY_BASE" => SecureRandom.hex(32),
      "JWT_SECRET_KEY" => SecureRandom.hex(32),
      "SUPER_ADMIN_API_KEY" => SecureRandom.hex(16)
    ) do
      result = Shiksha::Env.validate!(rails_env: "production")
      assert result[:ok], result[:errors].join(", ")
    end
  end

  test "validate requires all R2 vars when any is set" do
    with_env(
      "DATABASE_URL" => "postgres://localhost/db",
      "SECRET_KEY_BASE" => SecureRandom.hex(32),
      "JWT_SECRET_KEY" => SecureRandom.hex(32),
      "SUPER_ADMIN_API_KEY" => SecureRandom.hex(16),
      "R2_BUCKET" => "my-bucket",
      "R2_ACCESS_KEY_ID" => nil,
      "R2_SECRET_ACCESS_KEY" => nil,
      "R2_ENDPOINT" => nil
    ) do
      result = Shiksha::Env.validate!(rails_env: "production")
      refute result[:ok]
      assert_includes result[:errors].join, "R2"
    end
  end

  test "validate warns on dev placeholder secrets in production" do
    with_env(
      "DATABASE_URL" => "postgres://localhost/db",
      "SECRET_KEY_BASE" => "dev-local-secret-change-in-production",
      "JWT_SECRET_KEY" => SecureRandom.hex(32),
      "SUPER_ADMIN_API_KEY" => SecureRandom.hex(16)
    ) do
      result = Shiksha::Env.validate!(rails_env: "production")
      assert result[:ok]
      assert result[:warnings].any? { |w| w.include?("SECRET_KEY_BASE") }
    end
  end

  private

  def with_env(updates)
    previous = updates.keys.index_with { |key| ENV[key] }
    updates.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
