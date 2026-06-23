# frozen_string_literal: true

module Api
  module V1
    module Admin
      class NoticesController < ApplicationController
        include SchoolAdminAuth

        before_action :set_notice, only: %i[show update destroy]

        def index
          render json: { notices: Notice.recent.map { |notice| serialize_notice(notice) } }
        end

        def show
          render json: { notice: serialize_notice(@notice) }
        end

        def create
          notice = Notice.new(notice_params)
          notice.published_at ||= Time.current

          if notice.save
            render json: { notice: serialize_notice(notice) }, status: :created
          else
            render json: { errors: notice.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @notice.update(notice_params)
            render json: { notice: serialize_notice(@notice) }
          else
            render json: { errors: @notice.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @notice.destroy!
          head :no_content
        end

        private

        def set_notice
          @notice = Notice.find(params[:id])
        end

        def notice_params
          params.require(:notice).permit(:title, :body, :published_at)
        end

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
