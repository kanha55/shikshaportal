# frozen_string_literal: true

module Api
  module V1
    module Public
      class GalleryPhotosController < ApplicationController
        rescue_from ActiveRecord::StatementInvalid, with: :render_gallery_db_error
        rescue_from StandardError, with: :render_gallery_error

        def index
          school = ActsAsTenant.current_tenant
          return render json: { error: I18n.t("errors.school_not_found") }, status: :not_found unless school

          photos = GalleryPhoto.ordered
          render json: {
            gallery_photos: photos.filter_map { |photo| serialize(photo) if photo.image.attached? }
          }
        end

        private

        def serialize(photo)
          ::GalleryPhotoSerializer.serialize(photo, request: request)
        end

        def render_gallery_db_error(exception)
          Rails.logger.error("[GalleryPhoto] public database error: #{exception.class}: #{exception.message}")
          render json: { gallery_photos: [], warning: I18n.t("errors.gallery_db_not_ready") }
        end

        def render_gallery_error(exception)
          Rails.logger.error("[GalleryPhoto] public error: #{exception.class}: #{exception.message}")
          render json: { gallery_photos: [] }
        end
      end
    end
  end
end
