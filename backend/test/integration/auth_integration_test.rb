# frozen_string_literal: true

require "test_helper"
require "rack/test"
require "json"

class AuthIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
  end

  teardown do
    Rack::Attack.enabled = false
  end

  def test_login_returns_jwt_and_role
    host! "greenvalley.localhost"

    post api_v1_user_session_path,
         params: { user: { email: "principal@greenvalley.test", password: "password123" } },
         as: :json

    assert_response :success
    assert response.headers["Authorization"].present?, "Expected JWT in Authorization header"
    body = JSON.parse(response.body)
    assert_equal "school_admin", body.dig("user", "role")
  end

  def test_invalid_login_returns_401
    host! "greenvalley.localhost"

    post api_v1_user_session_path,
         params: { user: { email: "principal@greenvalley.test", password: "wrong" } },
         as: :json

    assert_response :unauthorized
  end

  def test_login_rate_limited_after_repeated_failures
    host! "greenvalley.localhost"

    10.times do
      post api_v1_user_session_path,
           params: { user: { email: "principal@greenvalley.test", password: "wrong" } },
           as: :json

      assert_response :unauthorized
    end

    post api_v1_user_session_path,
         params: { user: { email: "principal@greenvalley.test", password: "wrong" } },
         as: :json

    assert_response 429
    body = JSON.parse(response.body)
    assert body["error"].present?
  end

  def test_me_requires_jwt
    host! "greenvalley.localhost"

    get api_v1_auth_me_path, as: :json
    assert_response :unauthorized
  end

  def test_password_reset_email_enqueued
    host! "greenvalley.localhost"

    assert_emails 1 do
      post api_v1_user_password_path,
           params: { user: { email: "principal@greenvalley.test" } },
           as: :json
    end

    assert_response :success
  end

  def test_password_reset_rate_limited_after_repeated_requests
    host! "greenvalley.localhost"

    5.times do
      post api_v1_user_password_path,
           params: { user: { email: "principal@greenvalley.test" } },
           as: :json

      assert_response :success
    end

    post api_v1_user_password_path,
         params: { user: { email: "principal@greenvalley.test" } },
         as: :json

    assert_response 429
    body = JSON.parse(response.body)
    assert body["error"].present?
  end

  def test_student_login_includes_profile_fields
    host! "greenvalley.localhost"

    post api_v1_user_session_path,
         params: { user: { email: "rahul@greenvalley.test", password: "password123" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "student", body.dig("user", "role")
    assert_equal "10", body.dig("user", "class_name")
    assert_equal "A", body.dig("user", "section")
    assert_equal "101", body.dig("user", "roll_number")
  end

  def test_update_language_preference
    host! "greenvalley.localhost"

    post api_v1_user_session_path,
         params: { user: { email: "principal@greenvalley.test", password: "password123" } },
         as: :json

    auth = response.headers["Authorization"]
    assert auth.present?

    patch api_v1_auth_me_path,
          params: { user: { language_preference: "en" } },
          headers: { "Authorization" => auth },
          as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "en", body.dig("user", "language_preference")
  end
end
