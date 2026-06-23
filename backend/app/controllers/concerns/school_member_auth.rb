# frozen_string_literal: true

module SchoolMemberAuth
  extend ActiveSupport::Concern

  included do
    include JwtAuthenticatable
    before_action :authorize_school_member!
  end

  private

  def authorize_school_member!
    tenant = ActsAsTenant.current_tenant
    return if current_user && tenant && current_user.school_id == tenant.id

    render json: { error: "Forbidden" }, status: :forbidden and return
  end
end
