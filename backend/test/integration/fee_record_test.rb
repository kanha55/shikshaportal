# frozen_string_literal: true

require "test_helper"

class FeeRecordTest < ActionDispatch::IntegrationTest
  setup do
    @admin_auth = login_as("principal@greenvalley.test")
    @student = User.find_by!(email: "rahul@greenvalley.test")
  end

  test "admin records fee payment and downloads pdf receipt" do
    host! "greenvalley.localhost"

    post api_v1_admin_fees_path,
         params: {
           fee_record: {
             student_id: @student.id,
             fee_type: "tuition",
             amount: 1500,
             paid_on: Time.zone.today.iso8601,
             status: "paid"
           }
         },
         headers: auth_headers(@admin_auth),
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    fee_id = body.dig("fee_record", "id")
    receipt_number = body.dig("fee_record", "receipt_number")
    assert fee_id.present?
    assert receipt_number.present?

    get receipt_api_v1_admin_fee_path(fee_id), headers: auth_headers(@admin_auth)
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_operator response.body.bytesize, :>, 100

    student_auth = login_as("rahul@greenvalley.test")
    get api_v1_fees_path, headers: auth_headers(student_auth), as: :json

    assert_response :success
    summary = JSON.parse(response.body)
    assert_equal 1, summary["fee_records"].length
    assert_equal "paid", summary["fee_records"].first["status"]
  end

  test "admin can assign pending fee due" do
    host! "greenvalley.localhost"

    post api_v1_admin_fees_path,
         params: {
           fee_record: {
             student_id: @student.id,
             fee_type: "transport",
             amount: 500,
             due_date: (Time.zone.today + 7.days).iso8601,
             status: "pending"
           }
         },
         headers: auth_headers(@admin_auth),
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "pending", body.dig("fee_record", "status")
    assert_nil body.dig("fee_record", "receipt_number")
  end

  test "admin can filter fee records by year name and class" do
    host! "greenvalley.localhost"
    school = School.find_by!(subdomain: "greenvalley")

    second_student = ActsAsTenant.with_tenant(school) do
      User.create!(
        name: "Priya Singh",
        email: "priya@greenvalley.test",
        role: "student",
        school: school,
        roll_number: "102",
        class_name: "9",
        section: "B",
        parent_phone: "9876543211",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    create_fee(@student.id, paid_on: Time.zone.today.iso8601, amount: 1500)
    create_fee(second_student.id, paid_on: Time.zone.today.iso8601, amount: 800)

    get api_v1_admin_fees_path, headers: auth_headers(@admin_auth), as: :json
    assert_response :success
    assert_equal 2, JSON.parse(response.body)["fee_records"].length

    get api_v1_admin_fees_path,
        params: { student_name: "Priya" },
        headers: auth_headers(@admin_auth),
        as: :json
    assert_response :success, response.body
    body = JSON.parse(response.body)
    assert_equal 1, body["fee_records"].length
    assert_equal "Priya Singh", body["fee_records"].first["student_name"]

    get api_v1_admin_fees_path,
        params: { class_name: "10", section: "A" },
        headers: auth_headers(@admin_auth),
        as: :json
    body = JSON.parse(response.body)
    assert_equal 1, body["fee_records"].length
    assert_equal @student.id, body["fee_records"].first["student_id"]

    get api_v1_admin_fees_path,
        params: { year: Time.zone.today.year },
        headers: auth_headers(@admin_auth),
        as: :json
    assert_equal 2, JSON.parse(response.body)["fee_records"].length

    get api_v1_admin_fees_path,
        params: { year: Time.zone.today.year - 1 },
        headers: auth_headers(@admin_auth),
        as: :json
    assert_empty JSON.parse(response.body)["fee_records"]
  end

  private

  def create_fee(student_id, paid_on:, amount: 1000)
    post api_v1_admin_fees_path,
         params: {
           fee_record: {
             student_id: student_id,
             fee_type: "tuition",
             amount: amount,
             paid_on: paid_on,
             status: "paid"
           }
         },
         headers: auth_headers(@admin_auth),
         as: :json
    assert_response :created
  end

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
