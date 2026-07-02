# frozen_string_literal: true

module Api
  module V1
    class StudyMaterialsController < ApplicationController
      include SchoolMemberAuth

      before_action :authorize_student!

      def index
        materials = StudyMaterial.for_class(current_user.class_name).recent
        render json: {
          study_materials: materials.map { |material| serialize(material) }
        }
      end

      private

      def authorize_student!
        return if current_user.student?

        render json: { error: "Forbidden" }, status: :forbidden and return
      end

      def serialize(material)
        ::StudyMaterialSerializer.serialize(material, request: request)
      end
    end
  end
end
