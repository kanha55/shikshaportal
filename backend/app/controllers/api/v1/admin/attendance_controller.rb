# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AttendanceController < ApplicationController
        include SchoolAdminAuth

        def index
          date = parse_date(params[:date]) || Time.zone.today
          class_name = params[:class_name].to_s
          section = params[:section].to_s

          students = User.students
                         .where(class_name: class_name, section: section)
                         .order(:roll_number)
          records = AttendanceRecord.on_date(date)
                                    .for_class(class_name, section)
                                    .index_by(&:student_id)

          render json: {
            date: date.iso8601,
            class_name: class_name,
            section: section,
            students: students.map do |student|
              record = records[student.id]
              {
                student_id: student.id,
                name: student.name,
                roll_number: student.roll_number,
                status: record&.status
              }
            end,
            summary: build_summary(students.size, records.values)
          }
        end

        def create
          result = AttendanceBulkMarkService.call(
            school: ActsAsTenant.current_tenant,
            marked_by: current_user,
            date: params.require(:date),
            class_name: params.require(:class_name),
            section: params.require(:section),
            records: Array(params[:records]).map { |row| row.permit(:student_id, :status).to_h.symbolize_keys }
          )

          if result.success
            head :no_content
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def report
          date = parse_date(params[:date]) || Time.zone.today
          class_name = params[:class_name].to_s
          section = params[:section].to_s

          if class_name.blank?
            total = User.students.count
            records = AttendanceRecord.on_date(date)
          else
            total = User.students.where(class_name: class_name, section: section).count
            records = AttendanceRecord.on_date(date).for_class(class_name, section)
          end

          present = records.count { |row| row.status == "present" }
          absent = records.count { |row| row.status == "absent" }

          render json: {
            date: date.iso8601,
            class_name: class_name.presence,
            section: section.presence,
            total_students: total,
            marked: records.size,
            present: present,
            absent: absent,
            attendance_percent: total.zero? ? 0 : ((present.to_f / total) * 100).round(1)
          }
        end

        private

        def parse_date(value)
          return nil if value.blank?

          Date.parse(value.to_s)
        rescue Date::Error
          nil
        end

        def build_summary(total, records)
          present = records.count { |row| row.status == "present" }
          absent = records.count { |row| row.status == "absent" }
          {
            total: total,
            marked: records.size,
            present: present,
            absent: absent,
            unmarked: total - records.size
          }
        end
      end
    end
  end
end
