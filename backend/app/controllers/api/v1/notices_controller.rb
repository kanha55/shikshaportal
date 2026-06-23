# frozen_string_literal: true

module Api
  module V1
    class NoticesController < ApplicationController
      include SchoolMemberAuth

      def index
        notices = Notice.recent.limit(20)
        render json: { notices: notices.map { |notice| serialize_notice(notice) } }
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
