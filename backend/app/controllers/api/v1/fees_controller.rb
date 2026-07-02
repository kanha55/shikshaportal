# frozen_string_literal: true

module Api
  module V1
    class FeesController < ApplicationController
      include SchoolMemberAuth

      before_action :authorize_student!

      def index
        records = FeeRecord.where(student: current_user).recent
        pending = records.pending
        paid = records.paid

        render json: {
          summary: {
            pending_count: pending.count,
            pending_amount: pending.sum(:amount).to_f,
            paid_total: paid.sum(:amount).to_f
          },
          fee_records: records.map do |record|
            {
              id: record.id,
              fee_type: record.fee_type,
              amount: record.amount.to_f,
              due_date: record.due_date&.iso8601,
              paid_on: record.paid_on&.iso8601,
              status: record.status,
              receipt_number: record.receipt_number
            }
          end
        }
      end

      private

      def authorize_student!
        return if current_user.student?

        render json: { error: "Forbidden" }, status: :forbidden and return
      end
    end
  end
end
