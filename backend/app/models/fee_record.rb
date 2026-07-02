# frozen_string_literal: true

class FeeRecord < TenantRecord
  FEE_TYPES = %w[tuition transport exam other].freeze
  STATUSES = %w[pending paid].freeze

  belongs_to :school
  belongs_to :student, class_name: "User"
  belongs_to :recorded_by, class_name: "User"

  validates :fee_type, inclusion: { in: FEE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :amount, numericality: { greater_than: 0 }
  validates :receipt_number, uniqueness: { scope: :school_id }, allow_nil: true
  validate :paid_fields_consistency

  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_year, lambda { |year|
    where(
      "EXTRACT(YEAR FROM COALESCE(fee_records.paid_on, fee_records.due_date, fee_records.created_at)) = ?",
      year.to_i
    )
  }
  scope :matching_student_filters, lambda { |name: nil, class_name: nil, section: nil|
    return all if name.blank? && class_name.blank? && section.blank?

    students = User.students
    if name.present?
      term = "%#{ActiveRecord::Base.sanitize_sql_like(name.to_s)}%"
      students = students.where("users.name ILIKE ?", term)
    end
    students = students.where(class_name: class_name) if class_name.present?
    students = students.where(section: section) if section.present?
    where(student_id: students.select(:id))
  }

  private

  def paid_fields_consistency
    if status == "paid"
      errors.add(:paid_on, "is required for paid fees") if paid_on.blank?
      errors.add(:receipt_number, "is required for paid fees") if receipt_number.blank?
    elsif status == "pending" && receipt_number.present?
      errors.add(:receipt_number, "must be blank for pending fees")
    end
  end
end
