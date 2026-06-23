# frozen_string_literal: true

require "test_helper"

class NoticeCrudTest < ActionDispatch::IntegrationTest
  setup do
    @school = School.find_by!(subdomain: "greenvalley")
    @auth = login_as("principal@greenvalley.test")
  end

  test "school admin creates updates and deletes notice" do
    host! "greenvalley.localhost"

    post api_v1_admin_notices_path,
         params: { notice: { title: "Exam Notice", body: "Exams start Monday." } },
         headers: auth_headers,
         as: :json

    assert_response :created
    notice_id = JSON.parse(response.body).dig("notice", "id")
    assert notice_id.present?

    patch api_v1_admin_notice_path(notice_id),
          params: { notice: { title: "Updated Exam Notice" } },
          headers: auth_headers,
          as: :json

    assert_response :success
    assert_equal "Updated Exam Notice", JSON.parse(response.body).dig("notice", "title")

    get api_v1_admin_notices_path, headers: auth_headers, as: :json
    assert_response :success
    titles = JSON.parse(response.body)["notices"].map { |n| n["title"] }
    assert_includes titles, "Updated Exam Notice"

    delete api_v1_admin_notice_path(notice_id), headers: auth_headers, as: :json
    assert_response :no_content
  end

  test "student reads tenant notices ordered by date desc" do
    host! "greenvalley.localhost"
    ActsAsTenant.with_tenant(@school) do
      Notice.create!(title: "Older", body: "Old body", published_at: 2.days.ago, school: @school)
      Notice.create!(title: "Newer", body: "New body", published_at: 1.hour.ago, school: @school)
    end

    student = ActsAsTenant.with_tenant(@school) do
      User.create!(
        name: "Student Test",
        email: "student-notice@test.com",
        role: "student",
        school: @school,
        password: "password123",
        password_confirmation: "password123"
      )
    end

    post api_v1_user_session_path,
         params: { user: { email: student.email, password: "password123" } },
         as: :json
    student_auth = response.headers["Authorization"]

    get api_v1_notices_path, headers: { "Authorization" => student_auth }, as: :json
    assert_response :success

    notices = JSON.parse(response.body)["notices"]
    newer_idx = notices.index { |n| n["title"] == "Newer" }
    older_idx = notices.index { |n| n["title"] == "Older" }
    assert newer_idx
    assert older_idx
    assert_operator newer_idx, :<, older_idx
  end

  test "notices are tenant scoped" do
    host! "sunrise.localhost"
    sunrise = School.find_by!(subdomain: "sunrise")
    ActsAsTenant.with_tenant(sunrise) do
      Notice.create!(title: "Sunrise Only", body: "Private", published_at: Time.current, school: sunrise)
    end

    get api_v1_admin_notices_path, headers: auth_headers, as: :json
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
