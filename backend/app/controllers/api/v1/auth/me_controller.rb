# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MeController < ApplicationController
        include JwtAuthenticatable

        def show
          render json: { user: user_json(current_user) }
        end

        def update
          lang = params.dig(:user, :language_preference)
          unless lang.present? && School::LANGUAGES.include?(lang)
            return render json: { error: "Invalid language" }, status: :unprocessable_entity
          end

          current_user.update!(language_preference: lang)
          render json: { user: user_json(current_user) }
        end

        private

        def user_json(user)
          {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role,
            language_preference: user.language_preference,
            school_id: user.school_id,
            school_subdomain: user.school&.subdomain
          }
        end
      end
    end
  end
end
