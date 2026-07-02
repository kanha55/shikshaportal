# frozen_string_literal: true

module Api
  module V1
    module Public
      class NoticesController < ApplicationController
        def index
          school = ActsAsTenant.current_tenant
          return render json: { error: I18n.t("errors.school_not_found") }, status: :not_found unless school

          notices = Notice.recent.limit(5)

          render json: {
            notices: notices.map { |n| serialize_notice(n) }
          }
        end

        private

        def serialize_notice(notice)
          {
            id: notice.id,
            title: notice.title,
            body: notice.body,
            published_at: notice.published_at.iso8601
          }
        end
      end
    end
  end
end
