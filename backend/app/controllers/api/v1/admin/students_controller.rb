# frozen_string_literal: true

module Api
  module V1
    module Admin
      class StudentsController < ApplicationController
        include SchoolAdminAuth

        def index
          students = User.students.order(:class_name, :section, :roll_number)
          render json: { students: students.map { |student| serialize_student(student) } }
        end

        def import
          file = params[:file]
          return render json: { error: "CSV file required" }, status: :unprocessable_entity if file.blank?

          result = StudentBulkImportService.call(
            school: ActsAsTenant.current_tenant,
            csv_io: file.read
          )

          render json: {
            created_count: result.created_count,
            emails_sent: result.emails_sent,
            errors: result.errors,
            created: result.created
          }
        rescue ArgumentError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def serialize_student(student)
          {
            id: student.id,
            name: student.name,
            email: student.email,
            roll_number: student.roll_number,
            class_name: student.class_name,
            section: student.section,
            parent_phone: student.parent_phone
          }
        end
      end
    end
  end
end
