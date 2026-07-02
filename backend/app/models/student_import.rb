# frozen_string_literal: true

class StudentImport < TenantRecord
  STATUSES = %w[queued processing completed failed].freeze

  has_one_attached :csv_file

  validates :status, inclusion: { in: STATUSES }

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def finished?
    completed? || failed?
  end
end
