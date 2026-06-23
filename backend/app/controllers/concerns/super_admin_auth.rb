# frozen_string_literal: true

module SuperAdminAuth
  extend ActiveSupport::Concern

  included do
    skip_before_action :set_current_tenant
    before_action :authenticate_super_admin!
  end

  private

  def authenticate_super_admin!
    return if api_key_valid?
    return if jwt_super_admin?

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def api_key_valid?
    provided = request.headers["X-Super-Admin-Key"].to_s
    expected = ENV.fetch("SUPER_ADMIN_API_KEY", "")

    expected.present? && ActiveSupport::SecurityUtils.secure_compare(provided, expected)
  end

  def jwt_super_admin?
    user = warden.authenticate(scope: JwtAuthenticatable::DEVISE_SCOPE)
    user&.super_admin?
  end
end
