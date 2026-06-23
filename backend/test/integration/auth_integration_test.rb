# frozen_string_literal: true

require "test_helper"
require "rack/test"
require "json"

class AuthIntegrationTest < ActionDispatch::IntegrationTest
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
end
