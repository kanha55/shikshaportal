# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        def create
          user = User.find_by(email: sign_in_params[:email]&.downcase)

          unless user&.valid_password?(sign_in_params[:password]) && tenant_login_allowed?(user)
            return render json: { error: "Invalid email or password" }, status: :unauthorized
          end

          sign_in(user)
          render json: user_payload(user), status: :ok
        end

        def destroy
          if current_user
            sign_out(current_user)
            render json: { message: "Logged out" }, status: :ok
          else
            render json: { error: "Unauthorized" }, status: :unauthorized
          end
        end

        private

        def sign_in_params
          params.require(:user).permit(:email, :password)
        end

        def tenant_login_allowed?(user)
          return true if user.super_admin?

          tenant = ActsAsTenant.current_tenant
          return true if tenant.nil?

          user.school_id == tenant.id
        end

        def user_payload(user)
          { user: UserSerializer.as_json(user) }
        end
      end
    end
  end
end
