# frozen_string_literal: true

require "test_helper"

class AttendanceTest < ActionDispatch::IntegrationTest
  setup do
    @admin_auth = login_as("principal@greenvalley.test")
  end

  test "admin marks class attendance and student views summary" do
    host! "greenvalley.localhost"
    student = User.find_by!(email: "rahul@greenvalley.test")
    date = Time.zone.today.iso8601

    post api_v1_admin_attendance_path,
         params: {
           date: date,
           class_name: student.class_name,
           section: student.section,
           records: [
             { student_id: student.id, status: "present" }
           ]
         },
         headers: auth_headers(@admin_auth),
         as: :json

    assert_response :no_content

    get api_v1_admin_attendance_path,
        params: { date: date, class_name: student.class_name, section: student.section },
        headers: auth_headers(@admin_auth)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "present", body["students"].find { |row| row["student_id"] == student.id }["status"]

    student_auth = login_as("rahul@greenvalley.test")
    get api_v1_attendance_path, headers: auth_headers(student_auth), as: :json

    assert_response :success
    summary = JSON.parse(response.body)
    assert_equal 100.0, summary["attendance_percent"]
  end

  test "rejects future attendance date" do
    host! "greenvalley.localhost"
    student = User.find_by!(email: "rahul@greenvalley.test")

    post api_v1_admin_attendance_path,
         params: {
           date: (Time.zone.today + 1.day).iso8601,
           class_name: student.class_name,
           section: student.section,
           records: [{ student_id: student.id, status: "present" }]
         },
         headers: auth_headers(@admin_auth),
         as: :json

    assert_response :unprocessable_entity
  end

  private

  def login_as(email)
    host! "greenvalley.localhost"
    post api_v1_user_session_path,
         params: { user: { email: email, password: "password123" } },
         as: :json
    response.headers["Authorization"]
  end

  def auth_headers(token)
    { "Authorization" => token }
  end
end
