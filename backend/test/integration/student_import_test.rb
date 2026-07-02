# frozen_string_literal: true

require "test_helper"

class StudentImportTest < ActionDispatch::IntegrationTest
  setup do
    @school = School.find_by!(subdomain: "greenvalley")
  end

  test "imports students from csv and enqueues credential emails" do
    host! "greenvalley.localhost"
    csv = <<~CSV
      name,roll_number,class_name,section,parent_phone,email
      Import Student One,1101,10,A,9876543210,import-one@greenvalley.test
      Import Student Two,1102,10,A,9876543211,
    CSV

    assert_emails 2 do
      perform_import(csv)
    end

    assert_equal 2, @import_body["created_count"]
    assert_equal 2, @import_body["emails_sent"]
    assert_empty @import_body["errors"]
    assert User.students.exists?(roll_number: "1101", school: @school)
  end

  test "flags duplicate roll numbers in csv and database" do
    host! "greenvalley.localhost"
    ActsAsTenant.with_tenant(@school) do
      User.create!(
        name: "Existing Student",
        email: "existing@greenvalley.test",
        role: "student",
        school: @school,
        roll_number: "201",
        class_name: "9",
        section: "B",
        parent_phone: "9876500000",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    csv = <<~CSV
      name,roll_number,class_name,section,parent_phone
      One,301,10,A,9876543210
      Two,301,10,A,9876543211
      Three,201,10,A,9876543212
    CSV

    perform_import(csv)

    assert_equal 1, @import_body["created_count"]
    assert_equal 2, @import_body["errors"].length
    assert @import_body["errors"].any? { |e| e["error"].include?("Duplicate roll number in CSV") }
    assert @import_body["errors"].any? { |e| e["roll_number"] == "201" }
  end

  test "reports row validation errors" do
    host! "greenvalley.localhost"
    csv = <<~CSV
      name,roll_number,class_name,section,parent_phone
      ,103,10,A,9876543210
    CSV

    perform_import(csv)

    assert_equal 0, @import_body["created_count"]
    assert_equal 1, @import_body["errors"].length
    assert_includes @import_body["errors"].first["error"], "Missing required fields"
  end

  test "requires school admin auth" do
    host! "greenvalley.localhost"
    csv = "name,roll_number,class_name,section,parent_phone\nA,1,10,A,999\n"

    post import_api_v1_admin_students_path, params: { file: upload_csv(csv) }
    assert_response :unauthorized
  end

  test "creates single student from form submission" do
    host! "greenvalley.localhost"

    assert_emails 1 do
      perform_enqueued_jobs do
        post api_v1_admin_students_path,
             params: {
               student: {
                 name: "Form Student",
                 roll_number: "501",
                 class_name: "10",
                 section: "A",
                 parent_phone: "9876512345",
                 email: "formstudent@greenvalley.test"
               }
             },
             headers: auth_headers,
             as: :json
      end
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Form Student", body.dig("student", "name")
    assert User.students.exists?(roll_number: "501", school: @school)
  end

  test "rejects duplicate roll number on single create" do
    host! "greenvalley.localhost"
    attrs = {
      name: "First Student",
      roll_number: "888",
      class_name: "10",
      section: "A",
      parent_phone: "9876512345"
    }

    perform_enqueued_jobs do
      post api_v1_admin_students_path,
           params: { student: attrs },
           headers: auth_headers,
           as: :json
    end
    assert_response :created

    post api_v1_admin_students_path,
         params: { student: attrs.merge(name: "Second Student") },
         headers: auth_headers,
         as: :json

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"].join, "already exists"
  end

  test "imports one hundred students" do
    host! "greenvalley.localhost"
    rows = (1..100).map do |i|
      "Student #{i},#{1000 + i},10,A,98765#{format('%05d', i)}"
    end
    csv = "name,roll_number,class_name,section,parent_phone\n#{rows.join("\n")}\n"

    assert_emails 100 do
      perform_import(csv)
    end

    assert_equal 100, @import_body["created_count"]
    assert_empty @import_body["errors"]
  end

  test "returns import status while queued" do
    host! "greenvalley.localhost"
    csv = "name,roll_number,class_name,section,parent_phone\nA,1,10,A,999\n"

    post import_api_v1_admin_students_path,
         params: { file: upload_csv(csv) },
         headers: auth_headers

    assert_response :accepted
    body = JSON.parse(response.body)
    assert_equal "queued", body["status"]
    assert StudentImport.exists?(body["import_id"])
  end

  private

  def perform_import(csv)
    post import_api_v1_admin_students_path,
         params: { file: upload_csv(csv) },
         headers: auth_headers

    assert_response :accepted
    import_id = JSON.parse(response.body)["import_id"]

    perform_enqueued_jobs

    get imports_api_v1_admin_students_path(import_id: import_id), headers: auth_headers
    assert_response :success
    @import_body = JSON.parse(response.body)
    assert_equal "completed", @import_body["status"]
  end

  def auth_headers
    host! "greenvalley.localhost"
    post api_v1_user_session_path,
         params: { user: { email: "principal@greenvalley.test", password: "password123" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  def upload_csv(content)
    file = Tempfile.new(["students", ".csv"])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end
end
