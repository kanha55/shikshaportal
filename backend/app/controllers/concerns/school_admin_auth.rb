# frozen_string_literal: true

module SchoolAdminAuth
  extend ActiveSupport::Concern

  included do
    include JwtAuthenticatable
    before_action :authorize_school_admin!
  end

  private

  def authorize_school_admin!
    tenant = ActsAsTenant.current_tenant
    return if current_user&.school_admin? && current_user.school_id == tenant&.id
    return if current_user&.coaching_admin? && current_user.school_id == tenant&.id

    render json: { error: I18n.t("errors.forbidden") }, status: :forbidden and return
  end
end
