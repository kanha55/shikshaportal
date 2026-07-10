# frozen_string_literal: true

module Api
  module V1
    module Admin
      class StudyMaterialsController < ApplicationController
        include SchoolAdminAuth

        def index
          materials = StudyMaterial.recent
          render json: {
            study_materials: materials.map { |material| serialize(material) }
          }
        end

        def create
          file = material_params[:file]
          material = StudyMaterial.new(material_params.except(:file))
          material.school ||= ActsAsTenant.current_tenant

          if file.present?
            material.file.attach(
              io: file.open,
              filename: file.original_filename,
              content_type: file.content_type,
              key: study_material_blob_key(material.school, file.original_filename)
            )
          end

          if material.save
            render json: { study_material: serialize(material) }, status: :created
          else
            render json: { errors: material.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          material = StudyMaterial.find(params[:id])
          material.file.purge if material.file.attached?
          material.destroy!
          head :no_content
        end

        private

        def material_params
          params.require(:study_material).permit(:title, :class_name, :subject, :file)
        end

        # Store study materials in R2 under "<school>/study_materials/<uuid>.<ext>"
        # so each school's files are grouped in their own folder.
        def study_material_blob_key(school, filename)
          folder = school&.subdomain.presence || "school-#{school&.id}"
          extension = File.extname(filename.to_s).downcase
          "#{folder}/study_materials/#{SecureRandom.uuid}#{extension}"
        end

        def serialize(material)
          ::StudyMaterialSerializer.serialize(material, request: request)
        end
      end
    end
  end
end
