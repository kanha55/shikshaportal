# frozen_string_literal: true

class StudentBulkImportJob < ApplicationJob
  queue_as :default

  def perform(student_import_id)
    import = StudentImport.find(student_import_id)
    import.update!(status: "processing")

    ActsAsTenant.with_tenant(import.school) do
      csv_io = import.csv_file.download
      result = StudentBulkImportService.call(school: import.school, csv_io: csv_io)

      import.update!(
        status: "completed",
        result: {
          "created_count" => result.created_count,
          "emails_sent" => result.emails_sent,
          "errors" => result.errors,
          "created" => result.created
        }
      )
    end
  rescue ArgumentError => e
    import&.update!(status: "failed", error_message: e.message)
  rescue StandardError => e
    import&.update!(status: "failed", error_message: e.message)
    raise
  end
end
