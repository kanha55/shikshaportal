# frozen_string_literal: true

module SuperAdminAuth
  extend ActiveSupport::Concern

  included do
    skip_before_action :set_current_tenant
    before_action :authenticate_super_admin!
  end

  private

  def authenticate_super_admin!
    provided = request.headers["X-Super-Admin-Key"].to_s
    expected = ENV.fetch("SUPER_ADMIN_API_KEY", "")

    return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(provided, expected)

    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
