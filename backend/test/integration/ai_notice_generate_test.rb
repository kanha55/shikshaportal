# frozen_string_literal: true

require "test_helper"

class AiNoticeGenerateTest < ActionDispatch::IntegrationTest
  setup do
    @school = School.find_by!(subdomain: "greenvalley")
    @auth = login_as("principal@greenvalley.test")
  end

  test "school admin generates ai notice draft" do
    host! "greenvalley.localhost"

    post api_v1_admin_ai_notices_path,
         params: {
           rough_input: "kal school band hai barish ke karan",
           category: "holiday",
           bilingual: false,
           language: "hi"
         },
         headers: auth_headers,
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.dig("generated", "notice_title").present?
    assert body.dig("generated", "notice_body").present?
    assert body.dig("generated", "whatsapp_message").present?
    assert_equal 1, body.dig("usage", "today")
    assert_equal 50, body.dig("usage", "limit")
  end

  test "rejects invalid category" do
    host! "greenvalley.localhost"

    post api_v1_admin_ai_notices_path,
         params: { rough_input: "test", category: "invalid" },
         headers: auth_headers,
         as: :json

    assert_response :unprocessable_entity
  end

  test "student cannot generate ai notice" do
    host! "greenvalley.localhost"
    student_auth = login_as("rahul@greenvalley.test")

    post api_v1_admin_ai_notices_path,
         params: { rough_input: "test", category: "event" },
         headers: { "Authorization" => student_auth },
         as: :json

    assert_response :forbidden
  end

  private

  def login_as(email)
    host! "greenvalley.localhost"
    post api_v1_user_session_path,
         params: { user: { email: email, password: "password123" } },
         as: :json
    response.headers["Authorization"]
  end

  def auth_headers
    { "Authorization" => @auth }
  end
end
