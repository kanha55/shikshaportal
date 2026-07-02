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
          material = StudyMaterial.new(material_params)

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

        def serialize(material)
          StudyMaterialSerializer.serialize(material, request: request)
        end
      end
    end
  end
end
