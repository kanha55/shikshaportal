# frozen_string_literal: true

class AttendanceRecord < TenantRecord
  STATUSES = %w[present absent leave].freeze

  belongs_to :school
  belongs_to :student, class_name: "User"
  belongs_to :marked_by, class_name: "User"

  validates :date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :class_name, :section, presence: true
  validate :date_not_in_future

  scope :on_date, ->(date) { where(date: date) }
  scope :for_class, ->(class_name, section) { where(class_name: class_name, section: section) }
  scope :recent, -> { order(date: :desc) }

  private

  def date_not_in_future
    return if date.blank?
    return if date <= Time.zone.today

    errors.add(:date, "cannot be in the future")
  end
end
