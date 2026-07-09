# frozen_string_literal: true

module Api
  module V1
    module Public
      class GalleryPhotosController < ApplicationController
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
      end
    end
  end
end
