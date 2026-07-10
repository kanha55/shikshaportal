# frozen_string_literal: true

module Api
  module V1
    module Admin
      class GalleryPhotosController < ApplicationController
        include SchoolAdminAuth

        rescue_from ActiveRecord::StatementInvalid, with: :render_gallery_db_error
        rescue_from StandardError, with: :render_gallery_error

        MAX_GALLERY_SIZE = GalleryPhoto::MAX_FILE_SIZE

        def index
          photos = GalleryPhoto.ordered
          render json: {
            gallery_photos: photos.filter_map { |photo| safe_serialize(photo) }
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

          photo = GalleryPhoto.new(caption: photo_params[:caption])
          photo.school ||= ActsAsTenant.current_tenant
          photo.image.attach(
            io: image.open,
            filename: image.original_filename,
            content_type: image.content_type,
            key: gallery_blob_key(photo.school, image.original_filename)
          )

          if photo.save
            payload = safe_serialize(photo)
            return render json: { errors: ["Photo saved but URL could not be generated"] }, status: :unprocessable_entity unless payload

            render json: { gallery_photo: payload }, status: :created
          else
            render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActionController::ParameterMissing
          render json: { errors: ["Image file is required"] }, status: :unprocessable_entity
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.error("[GalleryPhoto] database error: #{e.class}: #{e.message}")
          render json: {
            errors: [I18n.t("errors.gallery_db_not_ready", default: "Gallery database is not ready. Run db:migrate on the server.")]
          }, status: :unprocessable_entity
        rescue ActiveStorage::Error => e
          Rails.logger.error("[GalleryPhoto] storage upload failed: #{e.class}: #{e.message}")
          render json: {
            errors: [I18n.t("errors.gallery_storage_failed", default: "Photo could not be saved. Check file storage configuration.")]
          }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error("[GalleryPhoto] upload failed: #{e.class}: #{e.message}")
          render json: {
            errors: [I18n.t("errors.gallery_storage_failed", default: "Photo could not be saved.")]
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

          render json: { gallery_photo: safe_serialize(photo.reload) }
        end

        private

        def photo_params
          params.require(:gallery_photo).permit(:caption, :image)
        end

        # Store gallery images in R2 under "<school>/gallery/<uuid>.<ext>" so
        # each school's photos live in their own folder.
        def gallery_blob_key(school, filename)
          folder = school&.subdomain.presence || "school-#{school&.id}"
          extension = File.extname(filename.to_s).downcase
          "#{folder}/gallery/#{SecureRandom.uuid}#{extension}"
        end

        def safe_serialize(photo)
          serialize(photo)
        rescue StandardError => e
          Rails.logger.error("[GalleryPhoto] serialize failed for #{photo.id}: #{e.class}: #{e.message}")
          nil
        end

        def serialize(photo)
          ::GalleryPhotoSerializer.serialize(photo, request: request)
        end

        def normalize_positions!
          GalleryPhoto.ordered.each_with_index do |photo, index|
            photo.update_column(:position, index + 1) if photo.position != index + 1
          end
        end

        def render_gallery_db_error(exception)
          Rails.logger.error("[GalleryPhoto] database error: #{exception.class}: #{exception.message}")
          render json: {
            errors: [I18n.t("errors.gallery_db_not_ready", default: "Gallery database is not ready. Run db:migrate on the server.")]
          }, status: :unprocessable_entity
        end

        def render_gallery_error(exception)
          Rails.logger.error("[GalleryPhoto] error: #{exception.class}: #{exception.message}")
          render json: {
            errors: [I18n.t("errors.gallery_storage_failed", default: "Photo could not be saved.")]
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
