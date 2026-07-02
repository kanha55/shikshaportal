# frozen_string_literal: true

class FeeRecordCreateService
  Result = Struct.new(:success, :fee_record, :errors, keyword_init: true)

  def self.call(school:, recorded_by:, attributes:)
    new(school:, recorded_by:, attributes:).call
  end

  def initialize(school:, recorded_by:, attributes:)
    @school = school
    @recorded_by = recorded_by
    @attributes = attributes
  end

  def call
    student = User.students.find_by(id: @attributes[:student_id])
    return failure([I18n.t("services.fees.student_not_found")]) unless student

    status = @attributes[:status].presence || "paid"
    paid_on = parse_date(@attributes[:paid_on]) || (status == "paid" ? Time.zone.today : nil)

    record = FeeRecord.new(
      school: @school,
      student: student,
      recorded_by: @recorded_by,
      fee_type: @attributes[:fee_type].to_s,
      amount: @attributes[:amount],
      due_date: parse_date(@attributes[:due_date]),
      paid_on: paid_on,
      status: status,
      notes: @attributes[:notes]
    )

    record.receipt_number = next_receipt_number if status == "paid"

    if record.save
      Result.new(success: true, fee_record: record, errors: [])
    else
      failure(record.errors.full_messages)
    end
  rescue ArgumentError
    failure([I18n.t("services.fees.invalid_amount")])
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end

  def next_receipt_number
    prefix = @school.subdomain.to_s.upcase[0, 2].presence || "SP"
    year = Time.zone.today.year
    sequence = FeeRecord.where(school: @school).where("receipt_number LIKE ?", "#{prefix}-#{year}-%").count + 1
    format("%s-%d-%04d", prefix, year, sequence)
  end

  def failure(errors)
    Result.new(success: false, fee_record: nil, errors: Array(errors))
  end
end
