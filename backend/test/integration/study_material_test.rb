# frozen_string_literal: true

require "test_helper"

class StudyMaterialTest < ActionDispatch::IntegrationTest
  setup do
    @school = School.find_by!(subdomain: "greenvalley")
    @admin_auth = login_as("principal@greenvalley.test")
    @pdf = fixture_file_upload("sample.pdf", "application/pdf")
  end

  test "admin uploads lists and deletes study material" do
    host! "greenvalley.localhost"

    post api_v1_admin_study_materials_path,
         params: {
           study_material: {
             title: "Math Chapter 1",
             class_name: "10",
             subject: "Mathematics",
             file: @pdf
           }
         },
         headers: auth_headers(@admin_auth)

    assert_response :created
    material_id = JSON.parse(response.body).dig("study_material", "id")
    assert material_id.present?

    get api_v1_admin_study_materials_path, headers: auth_headers(@admin_auth), as: :json
    assert_response :success
    titles = JSON.parse(response.body)["study_materials"].map { |row| row["title"] }
    assert_includes titles, "Math Chapter 1"

    delete api_v1_admin_study_material_path(material_id), headers: auth_headers(@admin_auth)
    assert_response :no_content
  end

  test "student sees only materials for own class" do
    host! "greenvalley.localhost"

    post api_v1_admin_study_materials_path,
         params: {
           study_material: {
             title: "Class 10 Science",
             class_name: "10",
             subject: "Science",
             file: @pdf
           }
         },
         headers: auth_headers(@admin_auth)

    post api_v1_admin_study_materials_path,
         params: {
           study_material: {
             title: "Class 9 Science",
             class_name: "9",
             subject: "Science",
             file: @pdf
           }
         },
         headers: auth_headers(@admin_auth)

    student_auth = login_as("rahul@greenvalley.test")
    get api_v1_study_materials_path, headers: auth_headers(student_auth), as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["study_materials"].length
    assert_equal "10", body["study_materials"].first["class_name"]
    assert body["study_materials"].first["download_url"].present?
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
