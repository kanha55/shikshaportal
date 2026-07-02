# frozen_string_literal: true

require "test_helper"

# T18 — End-to-end smoke journey mirroring production user flows (runs in CI).
class SmokeJourneyTest < ActionDispatch::IntegrationTest
  test "full tenant journey: admin setup, student Hindi login, English switch, all read APIs" do
    host! "greenvalley.localhost"
    school = School.find_by!(subdomain: "greenvalley")

    get api_v1_public_school_path
    assert_response :success
    public_body = JSON.parse(response.body)
    assert_equal "Green Valley School", public_body["name"]
    assert_equal "hi", public_body["default_language"]

    admin_auth = login("principal@greenvalley.test")
    assert admin_auth.present?

    post api_v1_admin_students_path,
         params: {
           student: {
             name: "Smoke Journey Student",
             roll_number: "t18-smoke",
             class_name: "10",
             section: "A",
             parent_phone: "9876599999",
             email: "smoke-journey@greenvalley.test"
           }
         },
         headers: auth_headers(admin_auth),
         as: :json
    assert_response :created
    student_id = JSON.parse(response.body).dig("student", "id")
    assert student_id.present?

    ActsAsTenant.with_tenant(school) do
      User.find(student_id).update!(
        password: "password123",
        password_confirmation: "password123"
      )
    end

    with_env("CURSOR_API_KEY" => nil, "ANTHROPIC_API_KEY" => nil) do
      post api_v1_admin_ai_notices_path,
           params: {
             rough_input: "kal school band hai barish ke karan",
             category: "holiday",
             bilingual: false,
             language: "hi"
           },
           headers: auth_headers(admin_auth),
           as: :json
    end
    assert_response :success
    ai_draft = JSON.parse(response.body).dig("generated", "notice_title")
    assert ai_draft.present?

    post api_v1_admin_notices_path,
         params: { notice: { title: ai_draft, body: "Smoke journey notice body." } },
         headers: auth_headers(admin_auth),
         as: :json
    assert_response :created
    notice_id = JSON.parse(response.body).dig("notice", "id")

    date = Time.zone.today.iso8601
    post api_v1_admin_attendance_path,
         params: {
           date: date,
           class_name: "10",
           section: "A",
           records: [{ student_id: student_id, status: "present" }]
         },
         headers: auth_headers(admin_auth),
         as: :json
    assert_response :no_content

    post api_v1_admin_fees_path,
         params: {
           fee_record: {
             student_id: student_id,
             fee_type: "tuition",
             amount: 500,
             paid_on: date,
             status: "paid"
           }
         },
         headers: auth_headers(admin_auth),
         as: :json
    assert_response :created

    pdf = fixture_file_upload("sample.pdf", "application/pdf")
    post api_v1_admin_study_materials_path,
         params: {
           study_material: {
             title: "Smoke Journey Material",
             class_name: "10",
             subject: "Science",
             file: pdf
           }
         },
         headers: auth_headers(admin_auth)
    assert_response :created

    student_auth = login("smoke-journey@greenvalley.test")
    me = JSON.parse(response.body)
    assert_equal "hi", me.dig("user", "language_preference")

    get api_v1_notices_path, headers: auth_headers(student_auth), as: :json
    assert_response :success
    notice_titles = JSON.parse(response.body)["notices"].map { |n| n["title"] }
    assert_includes notice_titles, ai_draft

    get api_v1_attendance_path, headers: auth_headers(student_auth), as: :json
    assert_response :success
    assert JSON.parse(response.body).key?("attendance_percent")

    get api_v1_fees_path, headers: auth_headers(student_auth), as: :json
    assert_response :success
    assert_equal 1, JSON.parse(response.body)["fee_records"].length

    get api_v1_study_materials_path, headers: auth_headers(student_auth), as: :json
    assert_response :success
    materials = JSON.parse(response.body)["study_materials"]
    assert materials.any? { |m| m["title"] == "Smoke Journey Material" }

    patch api_v1_auth_me_path,
          params: { user: { language_preference: "en" } },
          headers: auth_headers(student_auth),
          as: :json
    assert_response :success
    assert_equal "en", JSON.parse(response.body).dig("user", "language_preference")

    get api_v1_notices_path, headers: auth_headers(student_auth), as: :json
    assert_response :success

    admin_auth = login("principal@greenvalley.test")
    delete api_v1_admin_notice_path(notice_id), headers: auth_headers(admin_auth), as: :json
    assert_response :no_content
  end

  test "load: fifty students can login and fetch notices" do
    host! "greenvalley.localhost"
    school = School.find_by!(subdomain: "greenvalley")

    ActsAsTenant.with_tenant(school) do
      50.times do |i|
        User.create!(
          name: "Load Student #{i + 1}",
          email: "load-#{i + 1}@greenvalley.test",
          role: "student",
          school: school,
          roll_number: (9100 + i).to_s,
          class_name: "10",
          section: "A",
          parent_phone: "9876500000",
          language_preference: "hi",
          password: "password123",
          password_confirmation: "password123"
        )
      end
    end

    50.times do |i|
      email = "load-#{i + 1}@greenvalley.test"
      token = login(email)
      get api_v1_notices_path, headers: auth_headers(token), as: :json
      assert_response :success, "Student #{email} notices failed"
    end
  end

  private

  def login(email)
    host! "greenvalley.localhost"
    post api_v1_user_session_path,
         params: { user: { email: email, password: "password123" } },
         as: :json
    assert_response :success, "Login failed for #{email}: #{response.body}"
    response.headers["Authorization"]
  end

  def auth_headers(token)
    { "Authorization" => token }
  end

  def with_env(updates)
    previous = updates.keys.index_with { |key| ENV[key] }
    updates.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
