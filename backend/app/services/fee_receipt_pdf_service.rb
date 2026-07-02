# frozen_string_literal: true

class FeeReceiptPdfService
  def self.call(fee_record:)
    new(fee_record:).render
  end

  def initialize(fee_record:)
    @fee_record = fee_record
    @school = fee_record.school
    @student = fee_record.student
  end

  def render
    Prawn::Document.new(page_size: "A5", margin: 36) do |pdf|
      pdf.text @school.name, size: 18, style: :bold
      pdf.move_down 4
      pdf.text [@school.address, @school.phone].compact.join(" · "), size: 10, color: "666666"
      pdf.stroke_horizontal_rule
      pdf.move_down 12

      pdf.text "Fee Receipt", size: 14, style: :bold
      pdf.move_down 8
      pdf.text "Receipt No: #{@fee_record.receipt_number}", size: 11
      pdf.text "Date: #{@fee_record.paid_on&.strftime('%d %b %Y')}", size: 11
      pdf.move_down 10

      pdf.text "Student: #{@student.name}", size: 11
      pdf.text "Class: #{@student.class_name}-#{@student.section} · Roll: #{@student.roll_number}", size: 11
      pdf.text "Fee type: #{@fee_record.fee_type.titleize}", size: 11
      pdf.text "Amount paid: Rs. #{format('%.2f', @fee_record.amount)}", size: 12, style: :bold
      pdf.move_down 12

      if @fee_record.notes.present?
        pdf.text "Notes: #{@fee_record.notes}", size: 10
        pdf.move_down 8
      end

      pdf.text "Received by: #{@fee_record.recorded_by.name}", size: 10, color: "666666"
      pdf.move_down 16
      pdf.text "Thank you for your payment.", size: 10, align: :center, color: "666666"
    end.render
  end
end
