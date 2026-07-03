# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SchoolsController < ApplicationController
        include SuperAdminAuth

        def create
          result = SchoolRegistrationService.call(school_params)

          render json: serialize_school(result), status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        rescue KeyError => e
          render json: { error: I18n.t("errors.missing_parameter", param: e.key) }, status: :unprocessable_entity
        end

        private

        def school_params
          params.require(:school).permit(
            :name, :subdomain, :address, :phone,
            :principal_name, :principal_email, :board, :default_language
          )
        end

        def serialize_school(result)
          school = result.school
          {
            id: school.id,
            name: school.name,
            subdomain: school.subdomain,
            url: "https://#{school.subdomain}.#{ENV.fetch('APP_HOST', 'dskl.in')}",
            admin: {
              id: result.admin_user.id,
              email: result.admin_user.email,
              name: result.admin_user.name
            },
            message: I18n.t("messages.school_created", email: result.admin_user.email)
          }
        end
      end
    end
  end
end
