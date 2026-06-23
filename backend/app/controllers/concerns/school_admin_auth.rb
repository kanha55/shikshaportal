# frozen_string_literal: true

module SchoolAdminAuth
  extend ActiveSupport::Concern

  included do
    include JwtAuthenticatable
    before_action :authorize_school_admin!
  end

  private

  def authorize_school_admin!
    return if current_user&.school_admin? && current_user.school_id == ActsAsTenant.current_tenant&.id

    render json: { error: "Forbidden" }, status: :forbidden and return
  end
end
