# frozen_string_literal: true

module Api
  module V1
    module Admin
      class GalleryPhotosController < ApplicationController
        include SchoolAdminAuth

        MAX_GALLERY_SIZE = GalleryPhoto::MAX_FILE_SIZE

        def index
          photos = GalleryPhoto.ordered
          render json: {
            gallery_photos: photos.map { |photo| serialize(photo) }
          }
        end

        def create
          image = photo_params[:image]
          if image.blank?
            return render json: { errors: ["Image file is required"] }, status: :unprocessable_entity
          end

          if image.size > MAX_GALLERY_SIZE
            return render json: { errors: ["Photo must be smaller than 5 MB"] }, status: :unprocessable_entity
          end

          photo = GalleryPhoto.new(photo_params)
          photo.school ||= ActsAsTenant.current_tenant

          if photo.save
            render json: { gallery_photo: serialize(photo) }, status: :created
          else
            render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
          end
        rescue Aws::S3::Errors::ServiceError, ActiveStorage::Error => e
          Rails.logger.error("[GalleryPhoto] storage upload failed: #{e.class}: #{e.message}")
          render json: {
            errors: [I18n.t("errors.gallery_storage_failed", default: "Photo could not be saved. Check file storage configuration.")]
          }, status: :unprocessable_entity
        end

        def destroy
          photo = GalleryPhoto.find(params[:id])
          photo.image.purge if photo.image.attached?
          photo.destroy!
          normalize_positions!
          head :no_content
        end

        def move
          photo = GalleryPhoto.find(params[:id])
          direction = params.require(:direction)

          unless photo.move(direction)
            return render json: { errors: ["Cannot move photo #{direction}"] }, status: :unprocessable_entity
          end

          render json: { gallery_photo: serialize(photo.reload) }
        end

        private

        def photo_params
          params.require(:gallery_photo).permit(:caption, :image)
        end

        def serialize(photo)
          ::GalleryPhotoSerializer.serialize(photo, request: request)
        end

        def normalize_positions!
          GalleryPhoto.ordered.each_with_index do |photo, index|
            photo.update_column(:position, index + 1) if photo.position != index + 1
          end
        end
      end
    end
  end
end
