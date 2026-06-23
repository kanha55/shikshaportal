# frozen_string_literal: true

module JwtAuthenticatable
  extend ActiveSupport::Concern

  DEVISE_SCOPE = :api_v1_user

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    return if current_user

    render json: { error: "Unauthorized" }, status: :unauthorized and return
  end

  def current_user
    @current_user ||= warden.authenticate(scope: DEVISE_SCOPE)
  end

  def authorize_role!(*roles)
    return if current_user && roles.map(&:to_s).include?(current_user.role)

    render json: { error: "Forbidden" }, status: :forbidden
  end
end
