# frozen_string_literal: true

module Api
  module V1
    class AttendanceController < ApplicationController
      include SchoolMemberAuth

      before_action :authorize_student!

      def index
        records = AttendanceRecord.where(student: current_user).recent.limit(60)
        marked = records.reject { |row| row.status == "leave" }
        present_count = marked.count { |row| row.status == "present" }
        percent = marked.empty? ? 0 : ((present_count.to_f / marked.size) * 100).round(1)

        render json: {
          attendance_percent: percent,
          records: records.map do |record|
            {
              date: record.date.iso8601,
              status: record.status
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
