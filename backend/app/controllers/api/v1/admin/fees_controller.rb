# frozen_string_literal: true

module Api
  module V1
    module Admin
      class FeesController < ApplicationController
        include SchoolAdminAuth

        def index
          records = FeeRecord.includes(:student).recent.limit(100)
          records = records.where(student_id: params[:student_id]) if params[:student_id].present?
          records = records.where(status: params[:status]) if params[:status].present?
          records = records.for_year(params[:year]) if params[:year].present?
          records = records.matching_student_filters(
            name: params[:name],
            class_name: params[:class_name],
            section: params[:section]
          )

          render json: {
            fee_records: records.map { |record| serialize_fee(record) },
            summary: {
              pending_count: FeeRecord.pending.count,
              unpaid_amount: FeeRecord.pending.sum(:amount).to_f
            }
          }
        end

        def create
          result = FeeRecordCreateService.call(
            school: ActsAsTenant.current_tenant,
            recorded_by: current_user,
            attributes: fee_params.to_h.symbolize_keys
          )

          if result.success
            render json: { fee_record: serialize_fee(result.fee_record) }, status: :created
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def receipt
          record = FeeRecord.paid.find(params[:id])
          pdf = FeeReceiptPdfService.call(fee_record: record)

          send_data pdf,
                    filename: "#{record.receipt_number}.pdf",
                    type: "application/pdf",
                    disposition: "attachment"
        end

        private

        def fee_params
          params.require(:fee_record).permit(
            :student_id,
            :fee_type,
            :amount,
            :due_date,
            :paid_on,
            :status,
            :notes
          )
        end

        def serialize_fee(record)
          {
            id: record.id,
            student_id: record.student_id,
            student_name: record.student.name,
            class_name: record.student.class_name,
            section: record.student.section,
            fee_type: record.fee_type,
            amount: record.amount.to_f,
            due_date: record.due_date&.iso8601,
            paid_on: record.paid_on&.iso8601,
            status: record.status,
            receipt_number: record.receipt_number,
            notes: record.notes,
            receipt_url: record.status == "paid" ? receipt_api_v1_admin_fee_path(record) : nil
          }
        end
      end
    end
  end
end
