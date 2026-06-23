# frozen_string_literal: true

require "test_helper"

class PublicSchoolPageTest < ActionDispatch::IntegrationTest
  test "public school profile without login" do
    host! "greenvalley.localhost"

    get api_v1_public_school_path

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Green Valley School", body["name"]
    assert body["address"].present?
  end

  test "public notices returns latest five" do
    host! "greenvalley.localhost"
    school = School.find_by!(subdomain: "greenvalley")

    ActsAsTenant.with_tenant(school) do
      6.times do |i|
        Notice.create!(
          title: "Notice #{i}",
          body: "Body #{i}",
          published_at: i.days.ago,
          school: school
        )
      end
    end

    get api_v1_public_notices_path

    assert_response :success
    notices = JSON.parse(response.body)["notices"]
    assert_equal 5, notices.length
  end

  test "unknown subdomain returns 404" do
    host! "unknown.localhost"

    get api_v1_public_school_path

    assert_response :not_found
  end
end
