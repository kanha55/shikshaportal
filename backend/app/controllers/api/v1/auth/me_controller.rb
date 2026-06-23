# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MeController < ApplicationController
        include JwtAuthenticatable

        def show
          render json: {
            user: {
              id: current_user.id,
              email: current_user.email,
              name: current_user.name,
              role: current_user.role,
              language_preference: current_user.language_preference,
              school_id: current_user.school_id,
              school_subdomain: current_user.school&.subdomain
            }
          }
        end
      end
    end
  end
end
