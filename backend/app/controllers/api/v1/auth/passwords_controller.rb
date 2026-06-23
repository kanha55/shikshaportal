# frozen_string_literal: true

module Api
  module V1
    module Auth
      class PasswordsController < Devise::PasswordsController
        skip_before_action :set_current_tenant, raise: false
        respond_to :json

        def create
          self.resource = resource_class.send_reset_password_instructions(resource_params)
          render json: { message: "If that email exists, password reset instructions were sent." }, status: :ok
        end

        def update
          self.resource = resource_class.reset_password_by_token(resource_params)

          if resource.errors.empty?
            render json: { message: "Password updated successfully." }, status: :ok
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def resource_params
          params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
        end
      end
    end
  end
end
