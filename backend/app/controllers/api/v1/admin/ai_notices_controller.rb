# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AiNoticesController < ApplicationController
        include SchoolAdminAuth

        def create
          result = AiNoticeGeneratorService.new(
            school: ActsAsTenant.current_tenant,
            rough_input: params.require(:rough_input),
            category: params.require(:category),
            bilingual: ActiveModel::Type::Boolean.new.cast(params[:bilingual]),
            language: params[:language].presence || "hi"
          ).call

          AiGenerationLog.create!(
            school: ActsAsTenant.current_tenant,
            category: params[:category]
          )

          render json: {
            generated: result,
            usage: {
              today: AiNoticeGeneratorService.daily_usage_for(ActsAsTenant.current_tenant),
              limit: AiNoticeGeneratorService::DAILY_CAP
            }
          }
        rescue AiNoticeGeneratorService::GenerationError => e
          status = e.code == :daily_limit ? :too_many_requests : :unprocessable_entity
          render json: { errors: [e.message] }, status: status
        rescue StandardError => e
          Rails.logger.error("[AiNoticesController] #{e.class}: #{e.message}")
          render json: { errors: [I18n.t("services.ai.service_unavailable")] }, status: :internal_server_error
        end
      end
    end
  end
end
