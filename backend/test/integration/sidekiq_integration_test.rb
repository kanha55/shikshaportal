# frozen_string_literal: true

require "test_helper"

class SidekiqIntegrationTest < ActionDispatch::IntegrationTest
  test "health endpoint reports job adapter" do
    get api_v1_health_path

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "ok", body["status"]
    assert_equal "test", body.dig("jobs", "adapter")
    if ENV["REDIS_URL"].present?
      assert_equal "ok", body.dig("redis", "status")
    else
      assert_equal "skipped", body.dig("redis", "status")
    end
  end

  test "student bulk import job runs via active job" do
    school = School.find_by!(subdomain: "greenvalley")
    host! "greenvalley.localhost"

    ActsAsTenant.with_tenant(school) do
      import = StudentImport.create!(status: "queued")
      import.csv_file.attach(
        io: StringIO.new(<<~CSV),
          name,roll_number,class_name,section,parent_phone,email
          Sidekiq Student,2201,10,A,9876543210,sidekiq@greenvalley.test
        CSV
        filename: "students.csv",
        content_type: "text/csv"
      )

      assert_enqueued_with(job: StudentBulkImportJob, args: [import.id]) do
        StudentBulkImportJob.perform_later(import.id)
      end

      assert_emails 1 do
        perform_enqueued_jobs
      end

      import.reload
      assert_equal "completed", import.status
      assert_equal 1, import.result["created_count"]
      assert User.students.exists?(roll_number: "2201", school: school)
    end
  end

  test "school registration enqueues welcome email" do
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      SchoolRegistrationService.call(
        name: "Async School",
        subdomain: "asyncschool",
        principal_name: "Principal Async",
        principal_email: "admin@asyncschool.test",
        board: "cbse",
        default_language: "hi"
      )
    end
  end
end
