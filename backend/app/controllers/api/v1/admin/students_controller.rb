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

        def create
          result = StudentCreateService.call(
            school: ActsAsTenant.current_tenant,
            attributes: student_params
          )

          if result.success
            render json: {
              student: result.student,
              message: "Student created. Login email sent to #{result.student[:email]}."
            }, status: :created
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def import
          file = params[:file]
          return render json: { error: "CSV file required" }, status: :unprocessable_entity if file.blank?

          student_import = StudentImport.create!(status: "queued")
          student_import.csv_file.attach(
            io: file,
            filename: file.original_filename,
            content_type: file.content_type.presence || "text/csv"
          )

          StudentBulkImportJob.perform_later(student_import.id)

          render json: {
            import_id: student_import.id,
            status: student_import.status
          }, status: :accepted
        end

        def show_import
          student_import = StudentImport.find(params[:import_id])
          render json: serialize_import(student_import)
        end

        private

        def student_params
          params.require(:student).permit(:name, :roll_number, :class_name, :section, :parent_phone, :email)
        end

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

        def serialize_import(student_import)
          payload = {
            import_id: student_import.id,
            status: student_import.status,
            error_message: student_import.error_message
          }

          if student_import.completed?
            payload.merge!(
              created_count: student_import.result["created_count"],
              emails_sent: student_import.result["emails_sent"],
              errors: student_import.result["errors"],
              created: student_import.result["created"]
            )
          end

          payload
        end
      end
    end
  end
end
