# frozen_string_literal: true

class AttendanceBulkMarkService
  Result = Struct.new(:success, :errors, keyword_init: true)

  def self.call(school:, marked_by:, date:, class_name:, section:, records:)
    new(school:, marked_by:, date:, class_name:, section:, records:).call
  end

  def initialize(school:, marked_by:, date:, class_name:, section:, records:)
    @school = school
    @marked_by = marked_by
    @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    @class_name = class_name.to_s
    @section = section.to_s
    @records = records
  end

  def call
    return failure([I18n.t("services.attendance.future_date")]) if @date > Time.zone.today
    return failure([I18n.t("services.attendance.class_section_required")]) if @class_name.blank? || @section.blank?

    students = User.students.where(class_name: @class_name, section: @section).index_by(&:id)
    return failure([I18n.t("services.attendance.no_students")]) if students.empty?

    errors = []

    ActiveRecord::Base.transaction do
      @records.each do |entry|
        student_id = entry[:student_id].to_i
        status = entry[:status].to_s
        student = students[student_id]

        unless student && AttendanceRecord::STATUSES.include?(status)
          errors << I18n.t("services.attendance.invalid_entry", student_id: student_id)
          next
        end

        record = AttendanceRecord.find_or_initialize_by(
          school: @school,
          student: student,
          date: @date
        )
        record.assign_attributes(
          status: status,
          class_name: @class_name,
          section: @section,
          marked_by: @marked_by
        )
        record.save!
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    return failure(errors) if errors.any?

    Result.new(success: true, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  rescue Date::Error
    failure([I18n.t("services.attendance.invalid_date")])
  end

  private

  def failure(errors)
    Result.new(success: false, errors: Array(errors))
  end
end
