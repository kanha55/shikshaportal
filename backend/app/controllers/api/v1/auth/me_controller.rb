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
            return render json: { error: I18n.t("errors.invalid_language") }, status: :unprocessable_entity
          end

          current_user.update!(language_preference: lang)
          render json: { user: user_json(current_user) }
        end

        private

        def user_json(user)
          UserSerializer.as_json(user)
        end
      end
    end
  end
end
